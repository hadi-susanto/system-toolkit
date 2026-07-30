if (( ${__SYSKIT_PLYMOUTH_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_PLYMOUTH_LIB_LOADED=1

readonly __PLYMOUTH_GRUB_FILE="/etc/default/grub"
readonly __PLYMOUTH_ENABLED_LINE='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"'
readonly __PLYMOUTH_DISABLED_LINE='GRUB_CMDLINE_LINUX_DEFAULT=""'

##
# plymouth_state
#
# Resolves whether the GRUB default kernel command line enables or disables
# the Plymouth splash.
#
# Returns:
#   0 when Plymouth is enabled.
#   1 when Plymouth is disabled.
#   2 when the GRUB configuration file is unavailable or is a symbolic link.
#   3 when the GRUB setting is duplicated or has a custom value.
#
plymouth_state() {
    if [[ ! -f "$__PLYMOUTH_GRUB_FILE" ]] ||
        [[ -L "$__PLYMOUTH_GRUB_FILE" ]]; then
        return 2
    fi

    awk \
        -v enabled="$__PLYMOUTH_ENABLED_LINE" \
        -v disabled="$__PLYMOUTH_DISABLED_LINE" '
            index($0, "GRUB_CMDLINE_LINUX_DEFAULT=") == 1 {
                total += 1

                if ($0 == enabled) {
                    enabled_count += 1
                }

                if ($0 == disabled) {
                    disabled_count += 1
                }
            }

            END {
                if (total != 1) {
                    exit 3
                }

                if (enabled_count == 1) {
                    exit 0
                }

                if (disabled_count == 1) {
                    exit 1
                }

                exit 3
            }
        ' "$__PLYMOUTH_GRUB_FILE"
}
