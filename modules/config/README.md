# ⚙️ SysKit Configuration Modules

This directory contains the configuration modules discovered and orchestrated
by `syskit-cfg`. Each module owns its dependency checks, interaction, status
output, target handling, and configuration changes.

## Directory Layout

Every module uses a canonical `<category>/<module>` ID represented by its
directory path:

```text
modules/config/<category>/<module>/
```

For example, the canonical ID `term/kitty` uses:

```text
modules/config/term/kitty/
```

Module IDs use lowercase letters, numbers, and hyphens.

## Command Resolution

The `configure` and `status` commands accept either a canonical ID or a unique
module-name segment. `syskit-cfg <module>` is shorthand for
`syskit-cfg configure <module>`:

```bash
syskit-cfg configure kitty
syskit-cfg kitty
syskit-cfg status term/kitty
```

The resolver searches only `modules/config/`. A name that exists only
in another toolkit is not accepted; for example, `git` does not resolve here
even though `cli/git` exists in the shell payload. If the same module-name
segment exists under multiple configuration categories, the command fails as
ambiguous and requires a canonical ID.

Internal aliases are checked only when direct resolution finds no module. Alias
targets are validated against the current configuration module tree so stale
canonical IDs are rejected. Current aliases:

| Alias                         | Resolves to              |
|-------------------------------|--------------------------|
| `claude`                      | `misc/claude-code`       |
| `omp`                         | `term/oh-my-posh`        |
| `plvl10k`                     | `term/power-level-10k`   |
| `password`                    | `sys/password-asterisks` |
| `hide-password-asterisks`     | `sys/password-asterisks` |
| `sys/hide-password-asterisks` | `sys/password-asterisks` |

## Required Files

Every module must provide:

```text
metadata.conf
main.sh
status.sh
```

Modules may also provide `lib.sh` for helpers shared between `main.sh` and
`status.sh`. Most modules do; `term/oh-my-posh` and `term/starship` do not.

### `metadata.conf`

Provides the display information used by `syskit-cfg list`. It must contain a
non-empty `NAME` and `DESCRIPTION`:

```text
NAME="Kitty"
DESCRIPTION="Configure Kitty terminal preferences and startup sessions."
```

Metadata is parsed as data rather than executed as shell code. Keys must use
uppercase letters, digits, and underscores, and start with an uppercase letter.
Blank lines and lines beginning with `#` are ignored.

### `main.sh`

Performs the module's interactive configuration. `syskit-cfg configure` runs
it directly; there is no separate install or uninstall lifecycle. Modules
typically show their current status, then loop over a menu of actions that
adapt to the detected state (for example, enable versus disable). The module
decides how to handle existing targets and whether they can be changed safely.

Menu loops use the helpers from `$COMMON_LIB/prompt.sh` so they work with both
the plain-terminal and whiptail backends (set `DISABLE_WHIPTAIL=true` to force
the plain one). whiptail hides the normal screen while a dialog is open, so do
not print status or results with bare `printf`/`bash status.sh` around a menu:

- `show_status <heading> <command...>` runs the status command. Plain mode
  prints it; whiptail mode renders it inside the next menu dialog. Call it at
  the top of every loop iteration and keep `|| return $?`.
- `choose_option`, `confirm_action` and `ask_text` are the prompts.
- `pause_prompt` goes at the end of each loop iteration so action output stays
  readable (whiptail waits for Enter; plain mode just prints a blank line).

### `status.sh`

Inspects the module without changing the system. Each module owns its status
output format and returns non-zero only when inspection fails.

## Script Contract

Module scripts are executable-style Bash scripts. They must enable strict mode
immediately after the shebang, define `main()`, and end with `main "$@"`.

The framework invokes one module at a time and passes no user arguments to
`main.sh`. It exports:

- `CONFIG_MODULE_ID`: Canonical `<category>/<module>` ID.
- `CONFIG_MODULE_DIR`: Absolute path to the module directory.
- `CONFIG_MODULE_PAYLOAD`: Corresponding payload directory path.
- `CONFIG_FORCE`: `true` when `--force` is selected and `false` otherwise.

`syskit-cfg status` runs each module's `status.sh` directly.

### Privileged Commands

Modules that need administrator privileges call plain `sudo` after sourcing
`$COMMON_LIB/common.sh`. That library defines a `sudo` function that logs the
exact command and warns that a password may be requested before it runs the
real `sudo`. Precede every call with a `log_info` stating the human reason:

```bash
log_info "Administrator privileges are required to regenerate the GRUB configuration"

if ! sudo update-grub; then
    ...
fi
```

Direct calls such as `/usr/bin/sudo` or `command sudo` bypass the function and
are not logged.

## Payload Relationship

A module's optional payload mirrors its canonical path:

```text
modules/config/<category>/<module>/
payload/config/<category>/<module>/
```

For example:

```text
modules/config/term/kitty/
payload/config/term/kitty/
```

Module directories contain logic. Payload directories contain only files or
templates that the module may install or use while configuring the system.
Modules that do not require source assets may omit their payload directory.

## Current CLI Modules

| Canonical ID | Managed behavior                                                                      |
|--------------|---------------------------------------------------------------------------------------|
| `cli/rclone` | Creates or deletes systemd user services that automatically mount rclone remotes.     |

Managed services are written to `~/.config/systemd/user/rclone-<name>.service`;
no `sudo` is needed. The add action asks for:

- a service name (letters, digits, `-`, `_`), used for the unit name and
  `--volname`; an existing unit with that name is never replaced,
- the remote as `<remote>:` or `<remote>:<path>`, checked against
  `rclone listremotes`,
- the local mount location and `--cache-dir` (default `~/.cache/rclone`); both
  must be real, writable directories and are created after confirmation when
  missing,
- `--vfs-cache-mode` (default `writes`), `--vfs-cache-max-size` (default `1G`)
  and `--vfs-cache-max-age` (default `720h`).

The unit runs `rclone mount` as a `Type=notify` service, unmounts with
`fusermount3` (or `fusermount`), and is wanted by `default.target`, so it
starts when the user manager starts at login. It has no
`After=`/`Wants=network-online.target`: that target exists only in the system
manager and is ignored by user units, so `Restart=on-failure` retries when the
network is not ready yet. After the
file is written the module reloads the user manager and offers to run
`systemctl --user enable --now`. The delete action stops, disables, and removes
a selected unit. Status lists every `rclone-*.service` unit with its enabled
and active state.

## Current Development Modules

| Canonical ID | Managed behavior                                                                                                                      |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `dev/mise`   | Persists an optional Mise data directory override, installs Bash or Zsh initialization, and can activate either SysKit shell loader.  |
| `dev/sdkman` | Persists the SDKMAN! installation directory, installs Bash or Zsh initialization, and can activate either SysKit shell loader.        |

Set `SDKMAN_DIR` when SDKMAN! uses a custom installation directory:

```bash
SDKMAN_DIR="/absolute/sdkman/path" syskit-cfg configure dev/sdkman
```

When the variable is empty, the module falls back to `INSTALL_PATH` from the
Mint Provisioner registry
(`~/.local/state/mint-provisioner/registry/dev/sdkman.registry`). The resolved
directory must be absolute and can be stored through the first interactive
action in `~/.local/state/syskit/dev/sdkman/install-dir`.

Mise's `MISE_DATA_DIR` override, when set, is persisted through the module's
own interactive action in `~/.local/state/syskit/dev/mise/data-dir` and is
optional; without it, Mise uses its own default data directory. Mise is
installed into `delayed.d` and loaded after every regular shell module.

## Current GUI Modules

| Canonical ID | Managed behavior                                                                                       |
|--------------|--------------------------------------------------------------------------------------------------------|
| `gui/edge`   | Enables or disables the Microsoft Edge package cron jobs for every installed release channel.         |

Edge cron jobs live under `/opt/microsoft/msedge*/cron/`. A job is enabled
while its script is executable, because `run-parts` skips non-executable files;
the module toggles that mode with `sudo chmod`. The supported channels are
`stable`, `beta`, `dev`, and `canary`.

## Current IDE Modules

| Canonical ID    | Managed behavior                                                                          |
|-----------------|-------------------------------------------------------------------------------------------|
| `ide/jetbrains` | Sets or removes the `fs.inotify.max_user_watches` limit through a sysctl drop-in file.   |

JetBrains IDEs need one inotify watch per project directory and fall back to
slow recursive scans when the limit is reached. Following the
[JetBrains guide](https://youtrack.jetbrains.com/articles/SUPPORT-A-1715/Inotify-Watches-Limit-Linux),
the first menu action asks for a limit (default `1048576`, a positive integer
up to `2147483647`), writes `fs.inotify.max_user_watches = <limit>` to
`/etc/sysctl.d/idea.conf` with `sudo`, and applies it with
`sudo sysctl --system`. The second action removes that file and reloads sysctl.
The running kernel value is not reset by removal; it changes only when another
sysctl file sets it or after a reboot. Restart the IDE after changing the limit.
Status shows the configured value and the running kernel limit. A symbolic link,
non-regular file, or file without exactly one valid limit is reported as
`[invalid]`.

## Current Miscellaneous Modules

| Canonical ID       | Managed behavior                                                                                                                    |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `misc/claude-code` | Enables or disables the Claude Code auto-updater, installs Bash or Zsh initialization, and can activate either SysKit shell loader. |
| `misc/junie`       | Enables or disables the Junie CLI auto-update check.                                                                                |

Auto-update is toggled by setting `autoUpdaterStatus` to `enabled` or
`disabled` in `~/.claude/settings.json`. The module edits only that key
through `jq`, writing the result to a swap file created alongside the
settings file and renaming it into place, so an existing settings file is
never truncated or left partially written. The `claude` alias resolves to
`misc/claude-code`.

Junie's auto-update check is toggled the same way, by setting the boolean
`auto-update` key to `true` or `false` in `~/.junie/config.json` through the
same `jq` swap-file technique. Junie has no shell initialization and does not
participate in the shell toolkit.

## Current System Modules

| Canonical ID             | Managed behavior                                                                                  |
|--------------------------|---------------------------------------------------------------------------------------------------|
| `sys/apt-fast`           | Installs Bash or Zsh completion from the apt-fast vendor source or bundled local payloads.        |
| `sys/password-asterisks` | Enables or disables Linux Mint sudo password feedback by moving its managed sudoers file.         |
| `sys/plymouth`           | Enables the Plymouth splash or disables it for verbose boot output, then regenerates GRUB config. |

The apt-fast module also supports interactive removal of either installed
completion. Existing completion targets are preserved unless the module is run
with `--force` (for example, `syskit-cfg configure --force apt-fast`).

## Current Terminal Modules

| Canonical ID           | Managed behavior                                                                                                 |
|------------------------|------------------------------------------------------------------------------------------------------------------|
| `term/ghostty`         | Installs a managed optional include and the `syskit.ghostty` configuration asset.                                |
| `term/kitty`           | Installs a managed glob include plus independent `syskit.kitty` and `syskit.session` assets.                     |
| `term/oh-my-posh`      | Installs Bash or Zsh initialization and can activate either shell loader.                                        |
| `term/power-level-10k` | Persists the Powerlevel10k installation directory, installs Zsh initialization, and can activate the Zsh loader. |
| `term/starship`        | Installs Bash or Zsh initialization, can activate either shell loader, and edits `add_newline` through Starship. |

Set the Powerlevel10k installation directory when configuring it:

```bash
POWERLEVEL10K_INSTALL_DIR="/absolute/powerlevel10k/path" \
    syskit-cfg configure term/power-level-10k
```

When the variable is empty, the module falls back to `INSTALL_PATH` from the
Mint Provisioner registry
(`~/.local/state/mint-provisioner/registry/term/power-level-10k.registry`). The
resolved directory must be absolute and can be stored through the first
interactive action in
`~/.local/state/syskit/term/power-level-10k/install-dir`.

Starship, Oh My Posh, and Powerlevel10k integrations are mutually exclusive
within each shell. The shell module dependency checks inspect integration state
for the selected shell, so different prompt integrations may be used across
Bash and Zsh. The configuration `--force` option is forwarded to delegated
shell integration and loader commands.
