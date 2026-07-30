# Check required dependencies
if ! command -v bat >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m bat is not installed; skipping bat integration\n' >&2

    return 0
fi

# set global theme
export BAT_THEME="Dracula"

# colorizing pager for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# bat work like cat all the time (never page output)
alias bat-cat="bat --paging=never"
