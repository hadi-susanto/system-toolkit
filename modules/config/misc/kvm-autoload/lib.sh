if (( ${__SYSKIT_KVM_AUTOLOAD_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_KVM_AUTOLOAD_LOADED=1

readonly __KVM_AUTOLOAD_CONF="/etc/modprobe.d/syskit-kvm-autoload.conf"

##
# kvm_autoload_state
#
# Resolves whether the SysKit KVM blacklist file is present.
#
# Returns:
#   0 when KVM autoload is enabled (no blacklist file).
#   1 when KVM autoload is disabled (blacklist file present).
#   3 when the path is a symbolic link or not a regular file.
#
kvm_autoload_state() {
    if [[ -L "$__KVM_AUTOLOAD_CONF" ]]; then
        return 3
    fi

    if [[ -e "$__KVM_AUTOLOAD_CONF" ]] && [[ ! -f "$__KVM_AUTOLOAD_CONF" ]]; then
        return 3
    fi

    if [[ -f "$__KVM_AUTOLOAD_CONF" ]]; then
        return 1
    fi

    return 0
}

##
# virt_loaded_modules
#
# Lists loaded hypervisor kernel modules from lsmod: KVM (kvm, kvm_intel,
# kvm_amd), VirtualBox (vboxdrv), and VMware (vmmon).
#
# Output:
#   Prints "<module> <used-by-count> <used-by-names>" per matching module.
#
virt_loaded_modules() {
    lsmod 2>/dev/null |
        awk '$1 ~ /^(kvm|kvm_intel|kvm_amd|vboxdrv|vmmon)$/ { print $1, $3, $4 }' || true
}
