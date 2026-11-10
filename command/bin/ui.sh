#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
source "$COMMON_LIB/ui.sh"
source "$BIN_LIB/executables.sh"
source "$BIN_LIB/scope.sh"

readonly -a __BIN_UI_COMMANDS=(install uninstall status)
readonly -A __BIN_UI_COMMAND_LABELS=(
    [install]="Install executables"
    [uninstall]="Uninstall installed executables"
    [status]="Show local and global installation status"
)

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -h | --help)
                options_ref[HELP]=1
                ;;
            -*)
                log_error "Unknown ui option: $1"

                return 2
                ;;
            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done
}

__validate_options() {
    local args_name="$1"
    local -n args_ref="$args_name"

    if (( ${#args_ref[@]} > 0 )); then
        log_error "The ui command does not accept arguments: ${args_ref[*]}"

        return 2
    fi
}

##
# __executable_label <name> <install_dir>
#
# Describes the installed state of an executable in one installation
# directory for the executable checklists.
#
# Output:
#   Prints the label.
#
# Returns:
#   1 when the executable is not installed there.
#
__executable_label() {
    local name="$1"
    local install_dir="$2"
    local target="$install_dir/$name"
    local checksum_status=0

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        printf 'not installed\n'

        return 1
    fi

    checksums_match "$BIN_PAYLOAD/$name" "$target" 2>/dev/null || checksum_status=$?

    case "$checksum_status" in
        0)
            printf 'installed\n'
            ;;
        1)
            printf 'installed, update available\n'
            ;;
        *)
            printf 'installed, unknown version\n'
            ;;
    esac
}

##
# __detect_scope <install_dir> <names_name> <installed_name> <labels_name>
#
# Labels every executable for one installation directory and lists the ones
# installed there.
#
__detect_scope() {
    local install_dir="$1"
    local -n names_ref="$2"
    local -n installed_ref="$3"
    local -n labels_ref="$4"
    local name
    local label

    installed_ref=()
    labels_ref=()

    for name in "${names_ref[@]}"; do
        if label="$(__executable_label "$name" "$install_dir")"; then
            installed_ref+=("$name")
        fi

        labels_ref["$name"]="$label"
    done
}

__path_state() {
    if install_dir_in_path "$1"; then
        printf 'in PATH\n'
    else
        printf 'not in PATH\n'
    fi
}

##
# __choose_command <command_name> <local_dir> <local_count> <global_dir> <global_count> <total>
#
# Shows the welcome menu with the installed count of each scope and stores the
# selected command.
#
# Returns:
#   1 when the menu was cancelled.
#
__choose_command() {
    local -n command_ref="$1"
    local local_dir="$2"
    local local_count="$3"
    local global_dir="$4"
    local global_count="$5"
    local total="$6"
    local -a menu_items=()
    local menu_command

    for menu_command in "${__BIN_UI_COMMANDS[@]}"; do
        menu_items+=("$menu_command" "${__BIN_UI_COMMAND_LABELS[$menu_command]}")
    done

    command_ref="$(ui_dialog --cancel-button "Quit" --menu \
        "Welcome to SysKit executables.\n\nLocal  $local_dir: $local_count of $total installed, $(__path_state "$local_dir")\nGlobal $global_dir: $global_count of $total installed, $(__path_state "$global_dir")\n\nChoose what to do:" \
        "$UI_HEIGHT" "$UI_WIDTH" "${#__BIN_UI_COMMANDS[@]}" "${menu_items[@]}")" || return 1
}

##
# __choose_scope <command> <local_dir> <global_dir> <scope_name>
#
# Asks for the installation directory of a command and stores "local" or
# "global".
#
# Returns:
#   1 when the menu was cancelled.
#
__choose_scope() {
    local command="$1"
    local local_dir="$2"
    local global_dir="$3"
    local -n scope_ref="$4"
    local global_label="$global_dir (all users, requires sudo)"

    if (( EUID == 0 )); then
        global_label="$global_dir (all users)"
    fi

    scope_ref="$(ui_dialog --default-item "$scope_ref" --cancel-button "Back" --menu \
        "Where should executables be ${command}ed?" 12 "$UI_WIDTH" 2 \
        local "$local_dir (current user)" \
        global "$global_label")" || return 1
}

main() {
    local -A options=()
    local -a args=()
    local -a names=()
    local -a local_installed=()
    local -a global_installed=()
    local -A local_labels=()
    local -A global_labels=()
    local -A search=()
    local -a offered=()
    local -a executables=()
    local -a command_options=()
    local -a checklist_items=()
    local -a command_line=()
    local local_dir
    local global_dir
    local command=""
    local scope="local"
    local runner="syskit-bin"
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status == 0 )); then
        __validate_options args || status=$?
    fi

    if (( status != 0 )); then
        bash "$BIN_COMMAND/help.sh" ui >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        exec bash "$BIN_COMMAND/help.sh" ui
    fi

    local_dir="$(local_install_dir)" || return 1
    global_dir="$(global_install_dir)"

    ui_init "SysKit executables" || return 2

    list_bin_executables names
    __detect_scope "$local_dir" names local_installed local_labels
    __detect_scope "$global_dir" names global_installed global_labels

    while true; do
        __choose_command command \
            "$local_dir" "${#local_installed[@]}" \
            "$global_dir" "${#global_installed[@]}" \
            "${#names[@]}" || return 0

        executables=()
        command_line=("$command")
        checklist_items=()

        case "$command" in
            install | uninstall)
                __choose_scope "$command" "$local_dir" "$global_dir" scope || continue

                offered=("${names[@]}")
                if [[ "$command" == "uninstall" ]]; then
                    if [[ "$scope" == "global" ]]; then
                        offered=("${global_installed[@]}")
                    else
                        offered=("${local_installed[@]}")
                    fi
                fi

                ui_choose_items "$command" offered "${scope}_labels" search executables executable || continue

                if [[ "$scope" == "global" ]]; then
                    command_line+=("--global")
                fi

                if [[ "$command" == "install" ]]; then
                    checklist_items=(force "Overwrite existing destination files" OFF)
                fi
                ;;
        esac

        ui_choose_options "syskit-bin $command" command_options "${checklist_items[@]}" || continue
        command_line+=("${command_options[@]}" "${executables[@]}")

        runner="syskit-bin"
        if [[ "$scope" == "global" && "$command" != "status" ]] && (( EUID != 0 )); then
            runner="sudo syskit-bin"
        fi

        ui_confirm "$runner" "${command_line[@]}" || continue

        clear >/dev/tty 2>/dev/null || true

        if [[ "$runner" == "sudo syskit-bin" ]]; then
            log_info "Administrator privileges are required to $command executables in $global_dir"
            sudo bash "$SYSKIT_ROOT/syskit-bin" "${command_line[@]}" || return $?

            return 0
        fi

        exec bash "$BIN_COMMAND/main.sh" "${command_line[@]}"
    done
}

main "$@"
