# ⚙️ SysKit Configuration Modules

This directory contains the configuration modules discovered and orchestrated
by `syskit-cfg`. Each module owns its dependency checks, interaction, status
output, target handling, and configuration changes.

## Directory Layout

Every module uses a canonical `<category>/<module>` ID represented by its
directory path:

```text
command/config/modules/<category>/<module>/
```

For example, the canonical ID `term/kitty` uses:

```text
command/config/modules/term/kitty/
```

Module IDs use lowercase letters, numbers, and hyphens.

## Lifecycle Command Resolution

The `install` and `uninstall` commands accept either a canonical ID or a unique
module-name segment:

```bash
syskit-cfg install kitty
syskit-cfg uninstall term/kitty
```

The resolver searches only `command/config/modules/`. A name that exists only
in another toolkit is not accepted; for example, `git` does not resolve here
even though `cli/git` exists in the shell payload. If the same module-name
segment exists under multiple configuration categories, the command fails as
ambiguous and requires a canonical ID.

Internal aliases are checked only when direct resolution finds no module. Alias
targets are validated against the current configuration module tree so stale
canonical IDs are rejected. The legacy names `hide-password-asterisks` and
`sys/hide-password-asterisks` currently resolve to
`sys/password-asterisks`.

## Required Files

Every module must provide:

```text
metadata.conf
check_install_requirements.sh
install.sh
status.sh
```

### `metadata.conf`

Provides the display information used by `syskit-cfg list` and lifecycle
command headers. It must contain a non-empty `NAME` and `DESCRIPTION`:

```text
NAME="Kitty"
DESCRIPTION="Configure Kitty terminal preferences and startup sessions."
```

Metadata is parsed as data rather than executed as shell code. Keys must use
uppercase letters, digits, and underscores. Blank lines and lines beginning
with `#` are ignored.

### `check_install_requirements.sh`

Performs read-only dependency and installation-state checks before
`install.sh` runs.

The script returns:

- `0` to proceed with installation.
- `10` to skip an already satisfied installation.
- `20` to block an unavailable or unsafe installation.
- Any other non-zero value when the check fails unexpectedly.

The `--force` option overrides only status `10`. The check always runs, and
status `20` is never bypassed. Named result constants are available by sourcing
`lib/config/checks.sh`.

### `install.sh`

Performs the module's interactive installation and configuration. The module
decides how to handle existing targets and whether they can be updated safely.

### `status.sh`

Inspects the module without changing the system. Each module owns its status
output format and returns non-zero only when inspection fails.

## Optional Uninstallation

Safe uninstallation is optional. A module supports it when it provides:

```text
uninstall.sh
```

Modules may also provide:

```text
check_uninstall_requirements.sh
```

When present, `check_uninstall_requirements.sh` follows the same return-code
contract as `check_install_requirements.sh` and runs before `uninstall.sh`. It
must block uninstallation when the module cannot identify and reverse its
changes safely.

If uninstallation cannot be implemented safely, omit `uninstall.sh`.

## Script Contract

Lifecycle scripts are executable-style Bash scripts. They must enable strict
mode immediately after the shebang, define `main()`, and end with
`main "$@"`.

The framework invokes one module at a time and passes no user arguments to
lifecycle scripts. It exports:

- `CONFIG_MODULE_ID`: Canonical `<category>/<module>` ID.
- `CONFIG_MODULE_DIR`: Absolute path to the command module directory.
- `CONFIG_MODULE_PAYLOAD`: Corresponding payload directory path.

Install and uninstall lifecycle scripts also receive `CONFIG_FORCE`, which is
`true` when `--force` is selected and `false` otherwise.

## Payload Relationship

A module's optional payload mirrors its canonical command path:

```text
command/config/modules/<category>/<module>/
payload/config/<category>/<module>/
```

For example:

```text
command/config/modules/term/kitty/
payload/config/term/kitty/
```

Command modules contain lifecycle logic. Payload directories contain only
files or templates that the module may install or use while configuring the
system. Modules that do not require source assets may omit their payload
directory.

## Current Development Modules

| Canonical ID | Managed behavior                                                                                                               |
|--------------|--------------------------------------------------------------------------------------------------------------------------------|
| `dev/sdkman` | Persists the SDKMAN! installation directory, installs Bash or Zsh initialization, and can activate either SysKit shell loader. |

Set `SDKMAN_DIR` when SDKMAN! uses a custom installation directory:

```bash
SDKMAN_DIR="/absolute/sdkman/path" syskit-cfg install dev/sdkman
```

When the variable is empty, the module checks `$HOME/.sdkman`. The resolved
directory can be stored through the first interactive action in
`~/.local/state/syskit/dev/sdkman/install-dir`. Replacing a different or invalid
stored path requires `--force`.

## Current System Modules

| Canonical ID             | Managed behavior                                                                                  |
|--------------------------|---------------------------------------------------------------------------------------------------|
| `sys/apt-fast`           | Installs Bash or Zsh completion from the apt-fast vendor source or bundled local payloads.        |
| `sys/password-asterisks` | Enables or disables Linux Mint sudo password feedback by moving its managed sudoers file.         |
| `sys/plymouth`           | Enables the Plymouth splash or disables it for verbose boot output, then regenerates GRUB config. |

The apt-fast module also supports interactive removal of either installed
completion. Existing completion targets are preserved unless configuration
installation is run with `--force`.

## Current Terminal Modules

| Canonical ID      | Managed behavior                                                                                                 |
|-------------------|------------------------------------------------------------------------------------------------------------------|
| `term/ghostty`    | Installs a managed optional include and the `syskit.ghostty` configuration asset.                                |
| `term/kitty`      | Installs a managed glob include plus independent `syskit.kitty` and `syskit.session` assets.                     |
| `term/oh-my-posh` | Installs Bash or Zsh initialization and can activate either shell loader.                                        |
| `term/starship`   | Installs Bash or Zsh initialization, can activate either shell loader, and edits `add_newline` through Starship. |

Starship and Oh My Posh are mutually exclusive during normal configuration
installation. Their requirement checks return the skip status when the other
prompt executable is detected; `--force` explicitly overrides that skip.
