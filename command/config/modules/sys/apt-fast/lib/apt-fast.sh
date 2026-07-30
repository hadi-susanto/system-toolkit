if (( ${__SYSKIT_APT_FAST_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_APT_FAST_LIB_LOADED=1

readonly __APT_FAST_BASH_PAYLOAD="bash-autocompletion"
readonly __APT_FAST_ZSH_PAYLOAD="zsh-autocompletion"
readonly __APT_FAST_BASH_VENDOR_URL="https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/bash/apt-fast"
readonly __APT_FAST_ZSH_VENDOR_URL="https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/zsh/_apt-fast"
readonly __APT_FAST_BASH_TARGET="/etc/bash_completion.d/apt-fast"
readonly __APT_FAST_ZSH_TARGET="/usr/share/zsh/functions/Completion/Debian/_apt-fast"
