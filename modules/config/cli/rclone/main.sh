#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/path.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__ask_value() {
    local question="$1"
    local default_value="${2-}"

    if ! ask_text "$question" "$default_value"; then
        log_warn "Failed to obtain user input; the auto mount was not created"

        return 1
    fi
}

##
# __prepare_directory <label> <path>
#
# Expands a directory path, offers to create it when missing, and checks that
# it is a real directory writable by the current user.
#
# Output:
#   Prints the absolute directory path.
#
# Returns:
#   1 when the path is invalid, creation is declined or fails, or the
#   directory is unusable.
#
__prepare_directory() {
    local label="$1"
    local path="$2"
    local state=0

    # expand_path validates the input but resolves symbolic links, which would
    # hide a symlinked directory; normalize the same path without resolving.
    expand_path "$path" >/dev/null || return 1

    case "$path" in
        "~")
            path="$HOME"
            ;;
        "~/"*)
            path="$HOME/${path:2}"
            ;;
    esac

    if ! path="$(realpath -m -s -- "$path")"; then
        log_error "Failed to expand path: $path"

        return 1
    fi

    rclone_check_directory "$path" || state=$?

    if (( state == 1 )); then
        if ! can_write "$path"; then
            log_error "$label cannot be created by the current user: $path"

            return 1
        fi

        if ! confirm_action "$label does not exist. Create $path?"; then
            log_warn "$label was not created; the auto mount was not created"

            return 1
        fi

        if ! mkdir -p -- "$path"; then
            log_error "Failed to create $label: $path"

            return 1
        fi

        state=0
        rclone_check_directory "$path" || state=$?
    fi

    case "$state" in
        0)
            printf '%s\n' "$path"
            ;;
        2)
            log_error "$label must not be a symbolic link: $path"

            return 1
            ;;
        3)
            log_error "$label is not a directory: $path"

            return 1
            ;;
        *)
            log_error "$label is not writable by the current user: $path"

            return 1
            ;;
    esac
}

__ask_service_name() {
    local name

    name="$(__ask_value "Service name (used for rclone-<name>.service and --volname)?")" || return 1
    name="${name#"$__RCLONE_UNIT_PREFIX"}"
    name="${name%.service}"

    if ! rclone_valid_service_name "$name"; then
        log_error "Service name must start with a letter or digit and contain only letters, digits, '-' or '_': $name"

        return 1
    fi

    if [[ -e "$(rclone_unit_path "$name")" ]] || [[ -L "$(rclone_unit_path "$name")" ]]; then
        log_error "$(rclone_unit_name "$name") already exists; delete it first to recreate it"

        return 1
    fi

    printf '%s\n' "$name"
}

__ask_remote() {
    local remote
    local state=0

    remote="$(__ask_value "rclone remote to mount (for example onedrive: or onedrive:/path/sub-folder)?")" || return 1

    if ! rclone_valid_remote "$remote"; then
        log_error "Remote must use the form <remote>: or <remote>:<path>: $remote"

        return 1
    fi

    rclone_remote_exists "$remote" || state=$?

    case "$state" in
        0)
            printf '%s\n' "$remote"
            ;;
        1)
            log_error "Remote '${remote%%:*}' is not configured; available remotes: $(rclone listremotes 2>/dev/null | paste -sd ' ' -)"

            return 1
            ;;
        *)
            log_warn "Unable to list rclone remotes; '${remote%%:*}' could not be verified"
            printf '%s\n' "$remote"
            ;;
    esac
}

__ask_validated() {
    local question="$1"
    local default_value="$2"
    local validator="$3"
    local error_message="$4"
    local value

    value="$(__ask_value "$question" "$default_value")" || return 1

    if ! "$validator" "$value"; then
        log_error "$error_message: $value"

        return 1
    fi

    printf '%s\n' "$value"
}

__add_mount() {
    local name
    local remote
    local mount_dir
    local cache_mode
    local cache_dir
    local max_size
    local max_age
    local summary
    local confirmation_status

    if ! command -v rclone >/dev/null 2>&1; then
        log_error "rclone is required before an auto mount service can be created"

        return 1
    fi

    name="$(__ask_service_name)" || return 1
    remote="$(__ask_remote)" || return 1

    mount_dir="$(__ask_value "Local mount location?")" || return 1
    mount_dir="$(__prepare_directory "Mount location" "$mount_dir")" || return 1

    if [[ -n "$(find "$mount_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        log_warn "Mount location is not empty; rclone refuses to mount over a non-empty directory: $mount_dir"
    fi

    cache_mode="$(__ask_validated "VFS cache mode (--vfs-cache-mode: ${__RCLONE_CACHE_MODES[*]})?" \
        "$__RCLONE_DEFAULT_CACHE_MODE" rclone_valid_cache_mode \
        "Cache mode must be one of ${__RCLONE_CACHE_MODES[*]}")" || return 1

    cache_dir="$(__ask_value "Cache directory (--cache-dir)?" "$__RCLONE_DEFAULT_CACHE_DIR")" || return 1
    cache_dir="$(__prepare_directory "Cache directory" "$cache_dir")" || return 1

    max_size="$(__ask_validated "Maximum VFS cache size (--vfs-cache-max-size)?" \
        "$__RCLONE_DEFAULT_MAX_SIZE" rclone_valid_size \
        "Cache size must be a number with an optional B, K, M, G, T or P suffix")" || return 1

    max_age="$(__ask_validated "Maximum VFS cache age (--vfs-cache-max-age)?" \
        "$__RCLONE_DEFAULT_MAX_AGE" rclone_valid_duration \
        "Cache age must be a duration such as 720h, 30d or 1h30m")" || return 1

    # Pass the summary as the question so whiptail shows it inside the dialog.
    summary="The following auto mount will be created:"$'\n'
    summary+="  Service        : $(rclone_unit_path "$name")"$'\n'
    summary+="  Remote         : $remote"$'\n'
    summary+="  Mount location : $mount_dir"$'\n'
    summary+="  Cache mode     : $cache_mode"$'\n'
    summary+="  Cache directory: $cache_dir"$'\n'
    summary+="  Cache max size : $max_size"$'\n'
    summary+="  Cache max age  : $max_age"$'\n\n'
    summary+="Create this auto mount service?"

    if confirm_action "$summary"; then
        :
    else
        confirmation_status=$?

        if (( confirmation_status == 1 )); then
            log_info "The auto mount was not created"

            return 0
        fi

        return "$confirmation_status"
    fi

    write_rclone_unit "$name" "$remote" "$mount_dir" "$cache_mode" \
        "$cache_dir" "$max_size" "$max_age" || return $?

    if confirm_action "Enable $(rclone_unit_name "$name") at login and start it now?"; then
        enable_rclone_unit "$name"
    else
        log_info "Enable it later with: systemctl --user enable --now $(rclone_unit_name "$name")"
    fi
}

__delete_mount() {
    local selected
    local unit
    local -a units=()

    mapfile -t units < <(rclone_list_units)

    if (( ${#units[@]} == 0 )); then
        log_warn "No rclone auto mount services were found in $__RCLONE_UNIT_DIR"

        return 0
    fi

    if ! selected="$(
        choose_option $'Select the auto mount service to delete:\n----------------------------------------' "${units[@]}"
    )"; then
        return 1
    fi

    if [[ "$selected" == "X" ]]; then
        return 0
    fi

    unit="${units[selected - 1]}"

    if ! confirm_action "Stop, disable and delete $unit?"; then
        log_info "$unit was not deleted"

        return 0
    fi

    remove_rclone_unit "$unit"
}

main() {
    local selected

    while true; do
        show_status $'Current rclone Auto Mount Status:\n---------------------------------' \
            bash "$CONFIG_MODULE_DIR/status.sh" || return $?

        if ! selected="$(
            choose_option $'rclone Auto Mount Configuration:\n--------------------------------' \
                "Add new rclone auto mount via user service" \
                "Delete existing rclone auto mount user service"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        # A failed action is already logged; keep the menu open.
        case "$selected" in
            1)
                __add_mount || true
                ;;
            2)
                __delete_mount || true
                ;;
            X)
                return 0
                ;;
        esac

        pause_prompt
    done
}

main "$@"
