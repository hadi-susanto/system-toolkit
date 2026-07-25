# set global theme
export BAT_THEME="Dracula"

# colorizing pager for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# bat work like cat all the time (never page output)
alias cat="bat --paging=never"

# bat-help - Display a command's help with bat syntax highlighting.
#
# Usage:
#   bat-help [COMMAND [ARGS...]]
#   [binary] --help | bat-help
#
# Examples:
#   bat-help
#   git | bat-help
#   bat-help docker run
#   bat-help cargo build
#
# If no command is given, runs:
#   bat --plain --language=help
#
# Otherwise, runs:
#   COMMAND [ARGS...] --help 2>&1 | bat --plain --language=help
bat-help() {
    if (($# == 0)); then
        bat --plain --language=help
    else
        "$@" --help 2>&1 | bat --plain --language=help
    fi
}

# ensure that git is installed otherwise it will give error
if command -v git >/dev/null 2>&1; then
    # git-bat-diff - Preview modified files in the current Git repository with bat.
    #
    # Usage:
    #   git-bat-diff
    #
    # Displays all modified, tracked files (excluding deleted files) using
    # `bat --diff`, preserving paths relative to the current working directory.
    #
    # Equivalent to:
    #   git diff --name-only --relative --diff-filter=d -z |
    #     xargs -0 bat --diff
    git-bat-diff() {
        git diff --name-only --relative --diff-filter=d -z |
            xargs -0 bat --diff
    }
else
    git-bat-diff() {
        printf '\033[31m[ERROR]\033[0m git not installed, please install git and re-open terminal.\n' >&2
    }
fi
