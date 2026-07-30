# Check required dependencies
if ! command -v git >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m git is not installed; skipping git integration\n' >&2

    return 0
fi

alias gcm="git commit -m"
alias gp="git push"
alias gb="git branch"
alias gbr="git branch --remote"
alias gba="git branch --all"
alias gbd="git branch --delete"
alias gbD="git branch --delete --force"
alias gbdr="git branch --delete --remote"
alias gco="git checkout"
alias gcor="git checkout --recurse-submodules"
alias gsw="git switch"
alias gswc="git switch --create"
alias gf="git fetch"
alias gfo="git fetch origin"
