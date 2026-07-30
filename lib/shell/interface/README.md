# 🧩 Shell Interface

This directory contains shell interface implementations used by the SysKit shell
toolkit.

Each file represents one supported shell. The framework automatically discovers
available shell interfaces based on the filename. For example:

```text
lib/shell/interface/bash.sh
lib/shell/interface/zsh.sh
lib/shell/interface/fish.sh
lib/shell/interface/nu.sh
```

Adding a new shell requires implementing the interface contract described
below and providing its dedicated entrypoint. Once both are present, SysKit can
detect and use the shell.

Depending on the shell, additional shell-specific integration assets may also be
required under the `payload/shell/` directory. Some shells can reuse generic
`.sh` modules, while others (such as Fish or Nushell) require dedicated
integration files because they use different scripting languages.

## Entry Point Script

Each supported shell **must** provide a dedicated entry point script named:

```text
syskit-[shell]
```

For example:

```text
syskit-bash
syskit-zsh
syskit-fish
syskit-nu
```

At present, SysKit does not generate a generic launcher automatically. Requiring
a dedicated entry point for each supported shell keeps the startup logic
explicit and avoids mistakes caused by invoking the framework with an incorrect
shell name.

The entry point should perform only minimal bootstrap tasks, such as:

- Setting the required SysKit environment variables.
- Delegating execution to the shared shell framework.
- Passing the corresponding shell name to the framework.

A typical implementation should resemble the following:

```bash
#!/usr/bin/env bash

set -euo pipefail

# Resolve the SysKit installation directory.
export SYSKIT_ROOT=...

# Export shared library locations.
export COMMON_LIB=...
export SHELL_LIB=...
export SHELL_COMMAND=...
export SHELL_PAYLOAD=...

main() {
    # Delegate to the shared shell command dispatcher,
    # passing the shell identifier.
    exec bash "$SHELL_COMMAND/main.sh" <shell-name> "$@"
}

main "$@"
```

The implementation should remain minimal and follow the same structure as the
existing shell entry point.

# Interface Contract

## Table of Contents

- [`support_module`](#support_module)
- [`module_installed`](#module_installed)
- [`install_module`](#install_module)
- [`installed_module_path`](#installed_module_path)
- [`module_source_path`](#module_source_path)
- [`uninstall_module`](#uninstall_module)
- [`loader_active`](#loader_active)
- [`activate_loader`](#activate_loader)
- [`deactivate_loader`](#deactivate_loader)

---

## `support_module`

Checks whether a module provides integration compatible with this shell.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description                       |
|----------|-----------------------------------|
| `0`      | The module is supported.          |
| Non-zero | No compatible integration exists. |

---

## `module_installed`

Checks whether a shell module has already been installed.

Installed filenames use a flattened canonical ID. For example, `cli/git`
resolves to `cli_git.bash` for Bash and `cli_git.zsh` for Zsh.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description              |
|----------|--------------------------|
| `0`      | Module is installed.     |
| Non-zero | Module is not installed. |

---

## `install_module`

Installs a shell module.

The installed filename must flatten the canonical ID by replacing `/` with
`_`, then append the shell-specific extension.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description                    |
|----------|--------------------------------|
| `0`      | Module installed successfully. |
| Non-zero | Installation failed.           |

---

## `installed_module_path`

Returns the installed module file path.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description              |
|----------|--------------------------|
| `0`      | Module is installed.     |
| Non-zero | Module is not installed. |

### Output

Prints the absolute path of the installed module file.

---

## `module_source_path`

Returns the preferred compatible source file for a shell module.

The implementation should prioritize a shell-specific source file over the
generic source file. For example, the Bash interface should prefer
`[module].bash` and fall back to `[module].sh`.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description                       |
|----------|-----------------------------------|
| `0`      | A compatible source file exists.  |
| Non-zero | No compatible source file exists. |

### Output

Prints the absolute path to the preferred compatible source file.

---

## `uninstall_module`

Removes a previously installed shell module.

### Parameters

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| `canonical_id` | Shell module ID in `<category>/<module>` format. |

### Return Code

| Code     | Description                  |
|----------|------------------------------|
| `0`      | Module removed successfully. |
| Non-zero | Removal failed.              |

---

## `loader_active`

Checks whether the shell loader is currently active.

This includes both the loader file itself and any required shell startup
configuration.

### Parameters

None.

### Return Code

| Code     | Description         |
|----------|---------------------|
| `0`      | Loader is active.   |
| Non-zero | Loader is inactive. |

---

## `activate_loader`

Creates and activates the shell loader.

Implementations should install any required loader files and update the shell's
startup configuration.

### Parameters

None.

### Return Code

| Code     | Description                    |
|----------|--------------------------------|
| `0`      | Loader activated successfully. |
| Non-zero | Activation failed.             |

---

## `deactivate_loader`

Removes the shell loader and restores the shell startup configuration.

### Parameters

None.

### Return Code

| Code     | Description                  |
|----------|------------------------------|
| `0`      | Loader removed successfully. |
| Non-zero | Deactivation failed.         |
