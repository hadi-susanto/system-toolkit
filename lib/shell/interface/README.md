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

Adding a new shell only requires implementing the interface contract described
below. Once the interface file is present, SysKit automatically detects and uses
it.

Depending on the shell, additional shell-specific integration assets may also be
required under the `shell/` directory. Some shells can reuse generic `.sh`
modules, while others (such as Fish or Nushell) require dedicated integration
files because they use different scripting languages.

## Entry Point Script

Each supported shell **must** provide a dedicated entry point script named:

```text
syskit-[shell].sh
```

For example:

```text
syskit-bash.sh
syskit-zsh.sh
syskit-fish.sh
syskit-nu.sh
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
export SHELL_DIR=...

main() {
    # Delegate to the shared shell framework,
    # passing the shell identifier.
    exec bash "$SHELL_LIB/main.sh" <shell-name> "$@"
}

main "$@"
```

The implementation should remain minimal and follow the same structure as the
existing shell entry point. :contentReference[oaicite:0]{index=0}

# Interface Contract

## Table of Contents

- [`shell_display_name`](#shell_display_name)
- [`shell_installed`](#shell_installed)
- [`default_shell`](#default_shell)
- [`support_module`](#support_module)
- [`module_installed`](#module_installed)
- [`install_module`](#install_module)
- [`installed_module_path`](#installed_module_path)
- [`uninstall_module`](#uninstall_module)
- [`loader_active`](#loader_active)
- [`activate_loader`](#activate_loader)
- [`deactivate_loader`](#deactivate_loader)

---

## `shell_display_name`

Returns the human-readable name of the shell.

### Parameters

None.

### Return Code

Always returns `0`.

### Output

Prints the shell display name to standard output.

---

## `shell_installed`

Checks whether the shell is installed on the current system.

### Parameters

None.

### Return Code

| Code     | Description             |
|----------|-------------------------|
| `0`      | Shell is installed.     |
| Non-zero | Shell is not installed. |

---

## `default_shell`

Checks whether the shell is the user's configured default login shell.

### Parameters

None.

### Return Code

| Code     | Description                              |
|----------|------------------------------------------|
| `0`      | Shell is the user's default login shell. |
| Non-zero | Shell is not the default login shell.    |

---

## `support_module`

Checks whether a module provides integration compatible with this shell.

### Parameters

| Name     | Description        |
|----------|--------------------|
| `module` | Shell module name. |

### Return Code

| Code     | Description                       |
|----------|-----------------------------------|
| `0`      | The module is supported.          |
| Non-zero | No compatible integration exists. |

---

## `module_installed`

Checks whether a shell module has already been installed.

### Parameters

| Name     | Description        |
|----------|--------------------|
| `module` | Shell module name. |

### Return Code

| Code     | Description              |
|----------|--------------------------|
| `0`      | Module is installed.     |
| Non-zero | Module is not installed. |

---

## `install_module`

Installs a shell module.

### Parameters

| Name     | Description        |
|----------|--------------------|
| `module` | Shell module name. |

### Return Code

| Code     | Description                    |
|----------|--------------------------------|
| `0`      | Module installed successfully. |
| Non-zero | Installation failed.           |

---

## `installed_module_path`

Returns the installed module file path.

### Parameters

| Name     | Description        |
|----------|--------------------|
| `module` | Shell module name. |

### Return Code

| Code     | Description              |
|----------|--------------------------|
| `0`      | Module is installed.     |
| Non-zero | Module is not installed. |

### Output

Prints the absolute path of the installed module file.

---

## `uninstall_module`

Removes a previously installed shell module.

### Parameters

| Name     | Description        |
|----------|--------------------|
| `module` | Shell module name. |

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
