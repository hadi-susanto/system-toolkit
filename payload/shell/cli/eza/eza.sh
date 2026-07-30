# Check required dependencies
if ! command -v eza >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m eza is not installed; skipping eza integration\n' >&2

    return 0
fi

alias ls="eza --grid --color=always --icons=always --all --sort extension --group-directories-first"
alias ls-tree="eza --grid --tree --color=always --icons=always --all --sort extension --group-directories-first"
alias ll="eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso"
alias ll-tree="eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso"
alias ll-size="eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size"
alias ll-tree-size="eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size"
alias ll-size-tree="eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size"
