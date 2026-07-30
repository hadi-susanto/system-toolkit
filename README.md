# 🧰 System Toolkit

System Toolkit, or SysKit, is a collection of command-line tools for managing
binary, shell, and configuration integrations on a Linux system.

# 🎯 Objective

This project decouples configuration, integration, and preference management
from
[hadi-susanto/mint-provisioner](https://github.com/hadi-susanto/mint-provisioner/)
into the dedicated
[hadi-susanto/system-toolkit](https://github.com/hadi-susanto/system-toolkit)
repository.

The separation gives package installation and system provisioning a different
context from user-facing configuration and integration. It also allows Mint
Provisioner and SysKit to evolve and release their own versions independently.

Mint Provisioner can use SysKit as an installable component, while SysKit
remains independently installable and usable.

# 📥 Installation

Clone the latest project state without downloading its full Git history:

```bash
git clone --depth 1 https://github.com/hadi-susanto/system-toolkit.git
cd system-toolkit
```

Until installation automation is available, the toolkit entrypoints can be run
directly from the cloned repository with Bash.

## 📖 Help Examples

Show the basic help for each toolkit:

```bash
./syskit-bin help
./syskit-bash help
./syskit-zsh help
./syskit-cfg help
./syskit-cfg list
```

Pass a command name to `help` for command-specific usage and behavior:

```bash
./syskit-bin help install
./syskit-bin help status
./syskit-bash help activate
./syskit-zsh help status
./syskit-cfg help install
```

# 🧱 Project Structure

```text
system-toolkit/
├── syskit-bin             Binary toolkit entrypoint
├── syskit-bash            Bash toolkit entrypoint
├── syskit-zsh             Zsh toolkit entrypoint
├── syskit-cfg             Configuration toolkit entrypoint
├── command/
│   ├── bin/               Binary command dispatcher and scripts
│   ├── config/            Configuration command dispatcher and scripts
│   └── shell/             Shared Bash and Zsh command dispatcher and scripts
├── lib/
│   ├── common/            Shared logging, prompts, and process helpers
│   ├── bin/               Reusable binary toolkit libraries
│   ├── config/            Configuration metadata and module helpers
│   └── shell/             Reusable shell toolkit libraries and interfaces
└── payload/
    ├── bin/               Standalone executable scripts
    ├── config/            Configuration and preference assets
    └── shell/             Bash and Zsh integration assets
```

The `command/` directory contains the executable command dispatchers and
lifecycle scripts. Reusable, sourceable functions live under `lib/`, while
`payload/` contains the assets that those commands install or manage on the
system.

# ⚙️ How It Works

Each toolkit has a dedicated entrypoint:

```text
syskit-bin [command] [args...]
syskit-bash [command] [args...]
syskit-zsh [command] [args...]
syskit-cfg [command] [args...]
```

An entrypoint initializes the SysKit paths and invokes its toolkit's
`command/[toolkit]/main.sh` dispatcher. The dispatcher parses the first
argument as a command and explicitly routes it to a dedicated script such as
`install.sh`, `activate.sh`, or `status.sh`.

Bash and Zsh share the `command/shell/` dispatcher. Their entrypoints pass the
selected shell as the dispatcher's first internal parameter, allowing
shell-specific compatibility libraries from `lib/shell/` to be loaded when
needed.

Configuration and shell `install` and `uninstall` commands accept either a
canonical `<category>/<module>` ID or a unique module-name segment. For
example, `kitty` resolves to `term/kitty` for the configuration toolkit, while
`git` resolves to `cli/git` only for the shell toolkit. Resolution stays within
the selected toolkit's module directory, and an ambiguous module name is
rejected instead of selecting one arbitrarily.

The binary toolkit installs standalone executable scripts directly into a local
or global command directory. Other toolkit lifecycle commands establish their
command boundaries, help systems, scope handling, and routing independently.

# 🧩 Toolkits

**Binary toolkit**

The binary toolkit manages standalone executable scripts sourced from the
`payload/bin/` directory. It installs and uninstalls exact executable names in
`~/.local/bin` by default or `/usr/local/bin` with global scope. Its status
command compares SHA-256 checksums to report local and global state.

**Shell toolkit**

The shell toolkit manages Bash and Zsh integrations sourced from the
`payload/shell/` directory. Shell modules use canonical `<category>/<module>`
IDs internally; install and uninstall also accept unique short names such as
`git`. Installation places the integration in its designated location, while
activation makes the installed integration take effect.

**Configuration toolkit**

The configuration toolkit discovers configuration modules and orchestrates
their interactive installation one module at a time, along with safe
uninstallation when a module supports it. It also reports module-defined
status in independent sections. Install and uninstall accept either a unique
short name such as `kitty` or its canonical ID, `term/kitty`. Each module owns
its target handling and may use source files from the `payload/config/`
directory.

# 🔗 Relationship with Mint Provisioner

Mint Provisioner remains responsible for preparing a Linux Mint system and
installing its software dependencies. SysKit focuses on the configuration and
integration layer that follows installation.

Keeping these responsibilities in separate repositories provides clearer
project context, smaller release boundaries, and independent versioning. Mint
Provisioner can install SysKit as part of a provisioning workflow, but SysKit
does not require Mint Provisioner when installed or used independently.
