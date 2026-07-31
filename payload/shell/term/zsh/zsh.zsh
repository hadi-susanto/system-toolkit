# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# Shell behavior
setopt NO_BEEP

# Default programs
export EDITOR="nano"
export VISUAL="$EDITOR"
export PAGER="less"

# Locale
export LANG="en_US.UTF-8"

# User executables
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "${path[@]}"
)
export PATH

alias grep="grep --color=auto"

bindkey -e

if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi
