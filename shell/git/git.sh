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

##
# Pushes the current Git branch to origin and configures its upstream branch.
#
# Returns:
#   Non-zero when the branch cannot be resolved or the push fails.
#
gpsup() {
    local branch

    branch="$(git rev-parse --abbrev-ref HEAD)" || return $?
    git push --set-upstream origin "$branch"
}
