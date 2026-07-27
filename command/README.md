# ⚙️ SysKit Commands

This directory contains the main command scripts that act as SysKit's
executable application layer. Each root entrypoint initializes the required
paths and invokes the matching `main.sh` dispatcher in this directory.

Commands are organized by toolkit:

- `bin/` implements binary payload commands.
- `config/` implements configuration payload commands.
- `shell/` implements the shared Bash and Zsh payload commands.

Each toolkit directory contains its command dispatcher and lifecycle scripts,
such as `install.sh`, `uninstall.sh`, and `status.sh`. Reusable sourceable
functions belong under `lib/`, while files installed or managed by these
commands belong under `payload/`.
