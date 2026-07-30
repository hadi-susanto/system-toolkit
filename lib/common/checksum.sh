if (( ${__SYSKIT_CHECKSUM_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_CHECKSUM_LOADED=1

##
# checksums_match <source> <target>
#
# Compares the SHA-256 checksums of a source file and a target file.
#
# Parameters:
#   source    Source file to checksum.
#   target    Target file to checksum.
#
# Returns:
#   1 when the checksums differ.
#   2 when the source checksum cannot be read.
#   3 when the target checksum cannot be read.
#   127 when sha256sum is unavailable.
#
checksums_match() {
    local source="$1"
    local target="$2"
    local source_checksum
    local target_checksum

    if ! command -v sha256sum >/dev/null 2>&1; then
        return 127
    fi

    if ! source_checksum="$(sha256sum -- "$source" 2>/dev/null)"; then
        return 2
    fi

    if ! target_checksum="$(sha256sum -- "$target" 2>/dev/null)"; then
        return 3
    fi

    source_checksum="${source_checksum%% *}"
    target_checksum="${target_checksum%% *}"

    if [[ "$source_checksum" != "$target_checksum" ]]; then
        return 1
    fi

    return 0
}
