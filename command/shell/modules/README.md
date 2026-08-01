# Shell Module Policies and Dependency Checks

## Delayed Loading

A shell command module may contain a regular, non-symbolic-link `.delayed`
marker:

```text
command/shell/modules/<category>/<module>/.delayed
```

The shell installer resolves this marker and installs the integration into
`delayed.d` instead of `module.d`. Shell interfaces receive only the resolved
numeric `0` or `1` policy and do not read command module metadata directly.
Loaders source all regular modules before delayed modules.

SDKMAN! declares delayed loading. Existing installations can be migrated with:

```bash
syskit-bash install --force dev/sdkman
syskit-zsh install --force dev/sdkman
```

## Dependency Checks

Shell modules may provide a dedicated dependency script at:

```text
command/shell/modules/<category>/<module>/check_dependencies.sh
```

The shell installer runs this script in a separate Bash process before copying
the integration payload. The first positional argument is the active shell
interface identifier, such as `bash` or `zsh`. Scripts that inspect installed
integration state should source `lib/shell/interface_loader.sh` and load the
required contract explicitly:

```bash
local shell="${1:-}"

load_shell_interface "$shell" "module_installed" || return $?
```

Dependency scripts return `0` when installation may proceed and a non-zero
status after logging a useful error when a requirement is not satisfied. The
shell installer owns force policy: `--force` may continue after a failed
dependency check.

When no dedicated script exists, the installer checks whether the module-name
segment is available as a command.
