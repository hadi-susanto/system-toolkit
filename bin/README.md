# 📦 SysKit Binary Assets

This directory stores standalone executable scripts managed by the SysKit
binary toolkit.

Each installable executable is an extensionless regular file directly inside
this directory. Executable permission in the repository is optional because
installation always sets mode `0755`. Subdirectories and companion payloads are
not supported. The executable name `all` is reserved by the install command.

Local installation uses `~/.local/bin`, while global installation uses
`/usr/local/bin`. Command routing and implementation live under `lib/bin/`.
