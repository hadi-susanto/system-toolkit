# Check required dependencies
if ! type complete >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m programmable completion is unavailable; skipping partial-complete\n' >&2

    return 0
fi

##
# __syskit_partial_path_complete <mode>
#
# Expands every typed path segment of the word being completed as a prefix
# glob, so `/mn/d/p` matches `/mnt/data/programs`. Readline completes a single
# match fully and a multiple match up to the longest common prefix.
#
# Parameters:
#   mode    "dirs" matches directories only; "all" matches files and directories.
#
# Sets COMPREPLY to the matching paths.
#
__syskit_partial_path_complete() {
    local mode="$1"
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

    # A trailing slash or no typed segment lists the children.
    if [[ -z "$rest" ]] || [[ "$rest" == */ ]]; then
        glob+="*"
    fi

    # In "all" mode the last segment also matches files, so drop its "/".
    if [[ "$mode" == "all" ]] && [[ "$glob" == */ ]]; then
        glob="${glob%/}"
    elif [[ "$mode" == "dirs" ]] && [[ "$glob" != */ ]]; then
        glob+="/"
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

    COMPREPLY=("${replies[@]}")
}

##
# __syskit_partial_dir_complete
#
# Completion function for directory commands (cd, pushd).
#
__syskit_partial_dir_complete() {
    __syskit_partial_path_complete dirs
}

##
# __syskit_partial_default_complete <command> <word> <previous>
#
# Default completion function for commands without their own completion spec.
# Lazy-loads the bash-completion spec first. Without one, partially expands only
# words that look like paths (contain "/" or start with "~"); every other word
# is left to normal Bash completion.
#
# Returns:
#   124 when a completion spec was loaded and Bash must retry.
#
__syskit_partial_default_complete() {
    local cmd="$1"
    local cur="${COMP_WORDS[COMP_CWORD]}"

    COMPREPLY=()

    # Keep the bash-completion lazy loader working (git, ssh, mise, ...).
    if declare -F _completion_loader >/dev/null; then
        local rc=0
        local spec

        _completion_loader "$cmd" || rc=$?

        # The loader registers the no-op "_minimal" spec when the command has no
        # real spec. Drop it so the next Tab reaches this function again.
        spec="$(complete -p -- "$cmd" 2>/dev/null)" || true
        if [[ "$spec" == *"-F _minimal "* ]]; then
            complete -r -- "$cmd"
        elif (( rc == 124 )); then
            return 124
        fi
    fi

    if [[ "$cur" == */* ]] || [[ "$cur" == "~"* ]]; then
        __syskit_partial_path_complete all
    fi
}

# filenames: add "/" to directories and quote special characters.
# nospace:   do not append a space after a completed directory.
# default:   fall back to normal Bash completion when nothing matches.
complete -o filenames -o nospace -o default -F __syskit_partial_dir_complete cd pushd
complete -D -o filenames -o default -F __syskit_partial_default_complete
