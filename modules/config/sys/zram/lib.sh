if (( ${__SYSKIT_ZRAM_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_ZRAM_LOADED=1

__ZRAM_CONF="${__ZRAM_CONF:-/etc/default/zramswap}"
__ZRAM_SYSCTL_CONF="${__ZRAM_SYSCTL_CONF:-/etc/sysctl.d/99-zram.conf}"
readonly __ZRAM_SERVICE="zramswap.service"
readonly __ZRAM_ALGOS=(lzo lzo-rle lz4 lz4hc zstd deflate 842)
readonly __ZRAM_DEFAULT_ALGO="zstd"
readonly __ZRAM_DEFAULT_SIZE="4096"
readonly __ZRAM_DEFAULT_PRIORITY="100"
readonly __ZRAM_DEFAULT_SWAPPINESS="150"
readonly __ZRAM_DEFAULT_PAGE_CLUSTER="0"

##
# zram_installed
#
# Returns:
#   1 when zram-tools (zramswap.service) is not installed.
#
zram_installed() {
    if ! command -v systemctl >/dev/null 2>&1; then
        return 1
    fi

    systemctl cat "$__ZRAM_SERVICE" >/dev/null 2>&1
}

##
# zram_active_state
#
# Resolves whether a zram device is currently used as swap.
#
# Returns:
#   0 when a /dev/zram* swap device is active.
#   1 when no zram swap is active.
#
zram_active_state() {
    local name

    while read -r name; do
        if [[ "$name" == /dev/zram* ]]; then
            return 0
        fi
    done < <(swapon --noheadings --show=NAME 2>/dev/null || true)

    return 1
}

##
# zram_service_enabled_state
#
# Returns:
#   0 when zramswap.service is enabled at boot.
#   1 otherwise.
#
zram_service_enabled_state() {
    systemctl is-enabled --quiet "$__ZRAM_SERVICE" 2>/dev/null
}

##
# zram_conf_state
#
# Returns:
#   0 when the configuration file is a regular file.
#   1 when it is missing.
#   3 when it is a symbolic link or not a regular file.
#
zram_conf_state() {
    if [[ -L "$__ZRAM_CONF" ]]; then
        return 3
    fi

    if [[ -e "$__ZRAM_CONF" ]] && [[ ! -f "$__ZRAM_CONF" ]]; then
        return 3
    fi

    if [[ ! -e "$__ZRAM_CONF" ]]; then
        return 1
    fi

    return 0
}

##
# zram_conf_get <key>
#
# Reads the effective value of a KEY=value assignment (last one wins) without
# sourcing the file. Comments and surrounding quotes are ignored.
#
# Output:
#   Prints the value, or nothing when the key is not set.
#
zram_conf_get() {
    local key="$1"
    local line
    local value=""

    if [[ ! -f "$__ZRAM_CONF" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*"$key"=(.*)$ ]]; then
            value="${BASH_REMATCH[1]%%#*}"
            value="${value%"${value##*[![:space:]]}"}"
            value="${value#[\"\']}"
            value="${value%[\"\']}"
        fi
    done <"$__ZRAM_CONF"

    printf '%s\n' "$value"
}

##
# zram_device_size
#
# Output:
#   Prints the active zram disk size in human readable form (for example 4G).
#
# Returns:
#   1 when no zram device is available.
#
zram_device_size() {
    local size

    if ! command -v zramctl >/dev/null 2>&1; then
        return 1
    fi

    size="$(zramctl --noheadings --raw -o DISKSIZE 2>/dev/null | head -n1 || true)"

    if [[ -z "$size" ]]; then
        return 1
    fi

    printf '%s\n' "$size"
}

zram_valid_algo() {
    local algo="$1"
    local known

    for known in "${__ZRAM_ALGOS[@]}"; do
        if [[ "$algo" == "$known" ]]; then
            return 0
        fi
    done

    return 1
}

zram_valid_size() {
    [[ "$1" =~ ^[1-9][0-9]{0,8}$ ]]
}

zram_valid_percent() {
    [[ "$1" =~ ^[1-9][0-9]?$|^100$ ]]
}

zram_valid_priority() {
    [[ "$1" =~ ^(-1|0|[1-9][0-9]{0,4})$ ]] && (( $1 <= 32767 ))
}

##
# write_zram_conf <algo> <size_mib> <percent> <priority>
#
# Writes the zramswap configuration. Exactly one of size_mib or percent must
# be non-empty (zramswap lets PERCENT override SIZE).
#
# Returns:
#   1 when the target is invalid or the write fails.
#
write_zram_conf() {
    local algo="$1"
    local size="$2"
    local percent="$3"
    local priority="$4"
    local tmp
    local state=0

    zram_conf_state || state=$?

    if (( state == 3 )); then
        log_error "Invalid zram configuration file: $__ZRAM_CONF"

        return 1
    fi

    if ! tmp="$(mktemp)"; then
        log_error "Failed to create a temporary file"

        return 1
    fi

    {
        printf '# Managed by SysKit (sys/zram)\n'
        printf 'ALGO=%s\n' "$algo"

        if [[ -n "$percent" ]]; then
            printf 'PERCENT=%s\n' "$percent"
        else
            printf 'SIZE=%s\n' "$size"
        fi

        printf 'PRIORITY=%s\n' "$priority"
    } >"$tmp"

    log_info "Administrator privileges are required to write $__ZRAM_CONF"

    if ! sudo install -Dm0644 -- "$tmp" "$__ZRAM_CONF"; then
        rm -f -- "$tmp"
        log_error "Failed to write $__ZRAM_CONF"

        return 1
    fi

    rm -f -- "$tmp"
}

zram_valid_swappiness() {
    [[ "$1" =~ ^([0-9]|[1-9][0-9]|1[0-9][0-9]|200)$ ]]
}

zram_valid_page_cluster() {
    [[ "$1" =~ ^([0-9]|1[0-5])$ ]]
}

##
# zram_sysctl_live <name>
#
# Output:
#   Prints the running value of a sysctl (for example vm.swappiness).
#
# Returns:
#   1 when the value cannot be read.
#
zram_sysctl_live() {
    sysctl -n "$1" 2>/dev/null
}

##
# zram_sysctl_conf_get <name>
#
# Reads a persisted sysctl value from the managed sysctl file (last one wins)
# without sourcing it.
#
# Output:
#   Prints the value, or nothing when the key is not set.
#
zram_sysctl_conf_get() {
    local name="$1"
    local line
    local value=""

    if [[ ! -f "$__ZRAM_SYSCTL_CONF" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*"$name"[[:space:]]*=[[:space:]]*([^#[:space:]]*) ]]; then
            value="${BASH_REMATCH[1]}"
        fi
    done <"$__ZRAM_SYSCTL_CONF"

    printf '%s\n' "$value"
}

##
# write_zram_sysctl <swappiness> <page_cluster>
#
# Persists vm.swappiness and vm.page-cluster in the managed sysctl file,
# keeping any other lines in it, then applies the file to the running kernel.
#
# Returns:
#   1 when the target is invalid or the write or apply fails.
#
write_zram_sysctl() {
    local swappiness="$1"
    local page_cluster="$2"
    local tmp
    local line

    if [[ -L "$__ZRAM_SYSCTL_CONF" ]] ||
        { [[ -e "$__ZRAM_SYSCTL_CONF" ]] && [[ ! -f "$__ZRAM_SYSCTL_CONF" ]]; }; then
        log_error "Invalid sysctl file: $__ZRAM_SYSCTL_CONF"

        return 1
    fi

    if ! tmp="$(mktemp)"; then
        log_error "Failed to create a temporary file"

        return 1
    fi

    {
        if [[ -f "$__ZRAM_SYSCTL_CONF" ]]; then
            while IFS= read -r line; do
                if [[ ! "$line" =~ ^[[:space:]]*vm\.(swappiness|page-cluster)[[:space:]]*= ]]; then
                    printf '%s\n' "$line"
                fi
            done <"$__ZRAM_SYSCTL_CONF"
        fi

        printf 'vm.swappiness=%s\n' "$swappiness"
        printf 'vm.page-cluster=%s\n' "$page_cluster"
    } >"$tmp"

    log_info "Administrator privileges are required to write $__ZRAM_SYSCTL_CONF"

    if ! sudo install -Dm0644 -- "$tmp" "$__ZRAM_SYSCTL_CONF"; then
        rm -f -- "$tmp"
        log_error "Failed to write $__ZRAM_SYSCTL_CONF"

        return 1
    fi

    rm -f -- "$tmp"

    log_info "Administrator privileges are required to apply the sysctl values"

    if ! sudo sysctl -w "vm.swappiness=$swappiness" "vm.page-cluster=$page_cluster" >/dev/null; then
        log_error "Saved $__ZRAM_SYSCTL_CONF but failed to apply it to the running kernel"

        return 1
    fi
}
