autoload -Uz add-zsh-hook

typeset -g __syskit_starship_first_prompt=1

__syskit_starship_newline() {
    if (( __syskit_starship_first_prompt == 0 )); then
        print
    else
        __syskit_starship_first_prompt=0
    fi
}

add-zsh-hook precmd __syskit_starship_newline

eval "$(starship init zsh)"
