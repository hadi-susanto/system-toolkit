# ensure that git is installed otherwise it will give error
if command -v git >/dev/null 2>&1; then
    git-delta-diff() {
        git \
            -c core.pager=delta \
            -c interactive.diffFilter='delta --color-only' \
            -c delta.navigate=true \
            -c delta.dark=true \
            -c delta.side-by-side=true \
            diff "$@"
    }
else
    git-delta-diff() {
        printf '\033[31m[ERROR]\033[0m git not installed, please install git and re-open terminal.\n' >&2
    }
fi
