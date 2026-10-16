#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__print_autoload_status() {
    local state=0

    if kvm_autoload_state; then
        state=0
    else
        state=$?
    fi

    printf 'Autoload at Boot : '
    case "$state" in
        0)
            printf '%s[✓]%s enabled\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[✗]%s disabled (blacklisted)\n' "$COLOR_RED" "$COLOR_RESET"
            ;;
        *)
            log_error "Invalid KVM blacklist file: $__KVM_AUTOLOAD_CONF"
            printf '%s[?]%s invalid\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

__print_holder_status() {
    local name
    local count
    local users
    local holder
    local found=0
    local core=0

    while read -r name count users; do
        case "$name" in
            kvm_intel)
                holder="Linux KVM VT-x (kvm_intel)"
                ;;
            kvm_amd)
                holder="Linux KVM AMD-V (kvm_amd)"
                ;;
            vboxdrv)
                holder="VirtualBox (vboxdrv)"
                ;;
            vmmon)
                holder="VMware (vmmon)"
                ;;
            *)
                core=1
                continue
                ;;
        esac

        found=1
        printf 'Virt Holder      : %s[!]%s held by %s\n' \
            "$COLOR_YELLOW" "$COLOR_RESET" "$holder"
        printf '                   refcount %s%s\n' "$count" "${users:+, modules: $users}"
    done < <(virt_loaded_modules)

    if (( found )); then
        return 0
    fi

    if (( core )); then
        printf 'Virt Holder      : %s[✓]%s kvm core only, no vendor module (virt extension free)\n' \
            "$COLOR_GREEN" "$COLOR_RESET"

        return 0
    fi

    printf 'Virt Holder      : %s[✓]%s free (no hypervisor module loaded)\n' \
        "$COLOR_GREEN" "$COLOR_RESET"
}

main() {
    local failed=0

    if ! grep -qwE 'vmx|svm' /proc/cpuinfo 2>/dev/null; then
        printf 'CPU Virt Support : %s[?]%s vmx/svm not reported\n' \
            "$COLOR_YELLOW" "$COLOR_RESET"
    fi

    if ! __print_autoload_status; then
        failed=1
    fi

    __print_holder_status

    return "$failed"
}

main "$@"
