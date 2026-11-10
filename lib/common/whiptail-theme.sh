if (( ${__SYSKIT_WHIPTAIL_THEME_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_WHIPTAIL_THEME_LOADED=1

# Forced NEWT palette so whiptail dialogs stay blue on systems with another
# default palette. Pass it as NEWT_COLORS (and unset NEWT_COLORS_FILE).
readonly SYSKIT_WHIPTAIL_COLORS='root=white,blue
roottext=white,blue
shadow=,black
window=black,lightgray
border=black,lightgray
title=blue,lightgray
label=black,lightgray
textbox=black,lightgray
acttextbox=black,lightgray
listbox=black,lightgray
actlistbox=white,blue
sellistbox=black,lightgray
actsellistbox=white,blue
checkbox=black,lightgray
actcheckbox=white,blue
entry=black,cyan
disentry=gray,lightgray
button=black,cyan
actbutton=white,blue
compactbutton=black,lightgray
helpline=white,blue
emptyscale=,lightgray
fullscale=,blue'
