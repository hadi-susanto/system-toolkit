# ⚙️ SysKit Commands

This directory contains the main command scripts that act as SysKit's
executable application layer. Each root entrypoint initializes the required
paths and invokes the matching `main.sh` dispatcher in this directory.

Commands are organized by toolkit:

- `bin/` implements binary payload commands.
- `config/` implements configuration module discovery and lifecycle commands.
- `shell/` implements the shared Bash and Zsh payload commands.

Each toolkit directory contains its command dispatcher and lifecycle scripts,
such as `install.sh`, `uninstall.sh`, and `status.sh`. Reusable sourceable
functions belong under `lib/`, while files installed or managed by these
commands belong under `payload/`.

## Configuration Module Metadata

Configuration modules use the canonical directory layout:

```text
command/config/modules/[category]/[module]/
```

Each module must provide a `metadata.conf` containing a non-empty `NAME` and
`DESCRIPTION`:

```text
NAME="Kitty"
DESCRIPTION="Configure Kitty terminal preferences and sessions"
```

The configuration toolkit parses this file as metadata rather than executing
it as shell code. Metadata keys must use uppercase letters, digits, and
underscores. Blank lines and lines beginning with `#` are ignored.
