#!/usr/bin/env bash
set -euo pipefail

# Bootstrap installer for SysKit (System Toolkit).
#
# Clones (or updates) the repository and symlinks the syskit-bin, syskit-bash,
# syskit-zsh, and syskit-cfg entrypoints into ~/.local/bin. sudo is used only
# to install git when missing and for a global (/usr/local/bin) installation.
#
# Environment:
#   SYSKIT_DIR      Clone destination (default: ./system-toolkit).
#   SYSKIT_BRANCH   Branch to check out on a fresh clone (default: remote HEAD).
#   SYSKIT_FORCE    Set to "true" to replace existing entrypoint links.
#   SYSKIT_GLOBAL   Set to "true" to install to /usr/local/bin (uses sudo)
#                   instead of ~/.local/bin.

readonly SYSKIT_HTTPS_URL="https://github.com/hadi-susanto/system-toolkit.git"
readonly SYSKIT_SSH_URL="git@github.com:hadi-susanto/system-toolkit.git"
readonly -a SYSKIT_ENTRYPOINTS=(syskit-bin syskit-bash syskit-zsh syskit-cfg)

__log_info() {
    printf '[INFO] %s\n' "$*" >&2
}

__log_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

__log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

__validate_environment() {
    if (( EUID == 0 )); then
        __log_error "Do not run the bootstrap with sudo or as root."

        return 1
    fi

    if [[ -z "${HOME:-}" ]]; then
        __log_error "HOME is required."

        return 1
    fi
}

##
# __install_git
#
# Installs git through apt-get when it is missing. Dependencies of the
# installed executables are checked by each executable itself.
#
# Returns:
#   1 when apt-get or sudo is unavailable, or the installation fails.
#
__install_git() {
    if command -v git >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
        __log_error "git is required, and apt-get and sudo are needed to install it."

        return 1
    fi

    __log_info "Administrator privileges are required to install git"
    if ! sudo apt-get install -y git; then
        __log_error "Failed to install git"

        return 1
    fi
}

##
# __select_repo_url
#
# Output:
#   Prints the SSH URL when GitHub accepts SSH authentication, otherwise HTTPS.
#
__select_repo_url() {
    local output

    # ssh -T to GitHub exits 1 even on success, so inspect the greeting.
    output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true)"

    if [[ "$output" == *"successfully authenticated"* ]]; then
        printf '%s\n' "$SYSKIT_SSH_URL"

        return 0
    fi

    printf '%s\n' "$SYSKIT_HTTPS_URL"
}

##
# __sync_repository <dir> <branch>
#
# Clones the repository into <dir>, or fast-forwards an existing clone.
# The branch is only applied to a fresh clone.
#
__sync_repository() {
    local dir="$1"
    local branch="$2"
    local url
    local -a clone_args=()

    if [[ -d "$dir/.git" ]]; then
        if [[ ! -x "$dir/syskit-bin" ]]; then
            __log_error "Existing directory is not a SysKit clone: $dir"

            return 1
        fi

        __log_info "Updating existing clone: $dir"
        if ! git -C "$dir" pull --ff-only; then
            __log_error "Failed to fast-forward $dir"

            return 1
        fi

        return 0
    fi

    if [[ -e "$dir" ]]; then
        __log_error "Path exists and is not a SysKit clone: $dir"

        return 1
    fi

    if [[ -n "$branch" ]]; then
        clone_args+=(--branch "$branch")
    fi

    url="$(__select_repo_url)"
    __log_info "Cloning $url into $dir"
    if ! git clone "${clone_args[@]}" -- "$url" "$dir"; then
        __log_error "Failed to clone $url"

        return 1
    fi
}

##
# __link_entrypoints <dir> <force> <global>
#
# Symlinks the syskit-* entrypoints from <dir> into ~/.local/bin, or into
# /usr/local/bin through sudo when <global> is "true". The entrypoints resolve
# their symlink, so <dir> must stay in place.
#
# Returns:
#   1 when an entrypoint cannot be linked.
#
__link_entrypoints() {
    local dir="$1"
    local force="$2"
    local global="$3"
    local target_dir="$HOME/.local/bin"
    local -a runner=()
    local -a ln_args=(-s)
    local name
    local target

    if [[ "$global" == "true" ]]; then
        target_dir="/usr/local/bin"
        runner=(sudo)

        __log_info "Administrator privileges are required to link entrypoints into $target_dir"
    fi

    if [[ "$force" == "true" ]]; then
        ln_args+=(-f)
    fi

    if ! "${runner[@]}" mkdir -p -- "$target_dir"; then
        __log_error "Failed to create $target_dir"

        return 1
    fi

    for name in "${SYSKIT_ENTRYPOINTS[@]}"; do
        target="$target_dir/$name"

        if [[ -e "$target" || -L "$target" ]] && [[ "$force" != "true" ]]; then
            __log_warn "Already exists; skipping: $target"

            continue
        fi

        if ! "${runner[@]}" ln "${ln_args[@]}" -- "$dir/$name" "$target"; then
            __log_error "Failed to link $target"

            return 1
        fi

        __log_info "Linked $target -> $dir/$name"
    done

    if [[ ":$PATH:" != *":$target_dir:"* ]]; then
        __log_warn "$target_dir is not present in PATH"
    fi
}

main() {
    local dir="${SYSKIT_DIR:-$PWD/system-toolkit}"
    local branch="${SYSKIT_BRANCH:-}"
    local force="${SYSKIT_FORCE:-false}"
    local global="${SYSKIT_GLOBAL:-false}"

    __validate_environment || return $?
    __install_git || return $?
    __sync_repository "$dir" "$branch" || return $?
    __link_entrypoints "$dir" "$force" "$global" || return $?

    __log_info "Done. Repository: $dir"
    __log_info "Next: syskit-bin help"
}

main "$@"
