# Check required dependencies
if ! type complete >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m programmable completion is unavailable; skipping partial-cd\n' >&2

    return 0
fi

##
# __syskit_partial_dir_complete
#
# Completion function for directory commands. Expands every typed path segment
# as a prefix glob, so `/mn/d/p` matches `/mnt/data/programs/`. Readline
# completes a single match fully and a multiple match up to the longest common
# prefix.
#
# Sets COMPREPLY to the matching directories.
#
__syskit_partial_dir_complete() {
    # cur: word being completed; prefix: fixed path start; rest: part to glob.
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prefix=""
    local rest="$cur"
    local glob=""
    local seg
    local home_prefix=0
    local restore_nullglob
    local -a segs=()
    local -a matches=()
    local -a replies=()
    local match

    COMPREPLY=()

    # Bash does not expand "~" inside a glob, so replace it with $HOME by hand.
    if [[ "$rest" == "~" ]] || [[ "$rest" == "~/"* ]]; then
        prefix="$HOME/"
        rest="${rest#\~}"
        rest="${rest#/}"
        home_prefix=1
    elif [[ "$rest" == /* ]]; then
        prefix="/"
        rest="${rest#/}"
    fi

    # Split "mn/d/p" into (mn d p).
    if [[ -n "$rest" ]]; then
        IFS=/ read -ra segs <<<"$rest"
    fi

    # Turn each segment into "<escaped segment>*/": a prefix match on
    # directories only. Typed glob characters are escaped to stay literal.
    for seg in "${segs[@]}"; do
        seg="${seg//\\/\\\\}"
        seg="${seg//\*/\\*}"
        seg="${seg//\?/\\?}"
        seg="${seg//\[/\\[}"
        glob+="$seg*/"
    done

    # A trailing slash or no typed segment lists the child directories.
    if [[ -z "$rest" ]] || [[ "$rest" == */ ]]; then
        glob+="*/"
    fi

    # nullglob makes a pattern without matches expand to nothing.
    # shopt -p returns 1 when the option is off, which strict mode would trap.
    restore_nullglob="$(shopt -p nullglob)" || true
    shopt -s nullglob
    # shellcheck disable=SC2206 # intentional glob expansion
    matches=( $prefix$glob )
    eval "$restore_nullglob"

    # Drop the trailing slash (Readline re-adds it) and restore the "~" form.
    for match in "${matches[@]}"; do
        match="${match%/}"

        if (( home_prefix )); then
            match="~${match#"$HOME"}"
        fi

        replies+=("$match")
    done

    # Readline completes one match fully, or several up to their common prefix.
    COMPREPLY=("${replies[@]}")
}

# filenames: add "/" to directories and quote special characters.
# nospace:   do not append a space after a completed directory.
# default:   fall back to normal Bash completion when nothing matches.
complete -o filenames -o nospace -o default -F __syskit_partial_dir_complete cd pushd
