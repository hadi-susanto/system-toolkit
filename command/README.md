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

## Configuration Module Lifecycle

Every installable configuration module must provide:

```text
metadata.conf
install_check.sh
install.sh
```

Safe uninstallation is optional. A module supports it only when both files are
present:

```text
uninstall_check.sh
uninstall.sh
```

Check scripts return `0` to proceed, `10` to skip an already satisfied phase,
or `20` to block an unavailable or unsafe phase. Other non-zero values report
an unexpected check failure. The `--force` option overrides only status `10`;
checks always run and status `20` is never bypassed. Checks are read-only phase
gates; module interaction and system changes belong in the corresponding
install or uninstall script. Named result constants are available by sourcing
`lib/config/checks.sh`.

The framework invokes one module at a time and passes no user arguments to its
lifecycle scripts. It exports `CONFIG_MODULE_ID`, `CONFIG_MODULE_DIR`,
`CONFIG_MODULE_PAYLOAD`, and the `true` or `false` value `CONFIG_FORCE`.
