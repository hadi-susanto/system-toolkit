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
bash ./syskit-bin.sh help
bash ./syskit-bash.sh help
bash ./syskit-zsh.sh help
bash ./syskit-cfg.sh help
```

Pass a command name to `help` for command-specific usage and behavior:

```bash
bash ./syskit-bin.sh help install
bash ./syskit-bin.sh status
bash ./syskit-bash.sh help enable
bash ./syskit-zsh.sh help status
bash ./syskit-cfg.sh help install
```

# 🧱 Project Structure

```text
system-toolkit/
├── syskit-bin.sh          Binary toolkit entrypoint
├── syskit-bash.sh         Bash toolkit entrypoint
├── syskit-zsh.sh          Zsh toolkit entrypoint
├── syskit-cfg.sh          Configuration toolkit entrypoint
├── bin/                   Standalone executable scripts
├── config/                Configuration and preference assets
├── shell/                 Bash and Zsh integration assets
└── lib/
    ├── common/            Shared logging and argument helpers
    ├── bin/               Binary toolkit controller and commands
    ├── config/            Configuration toolkit controller and commands
    └── shell/             Shared Bash and Zsh controller and commands
```

The top-level asset directories contain the files managed by SysKit. The
matching directories under `lib/` contain the command implementations that
operate on those assets. Their controllers live in `lib/bin/`, `lib/config/`,
and `lib/shell/`.

# ⚙️ How It Works

Each toolkit has a dedicated entrypoint:

```text
syskit-bin.sh [command] [args...]
syskit-bash.sh [command] [args...]
syskit-zsh.sh [command] [args...]
syskit-cfg.sh [command] [args...]
```

An entrypoint initializes the SysKit paths and invokes its toolkit controller.
The controller parses the first argument as a command and explicitly routes it
to a dedicated script such as `install.sh`, `enable.sh`, or `status.sh`.

Bash and Zsh share the `lib/shell/` controller. Their entrypoints pass the
selected shell as the controller's first internal parameter, allowing
shell-specific compatibility implementations to be loaded when needed.

The binary toolkit installs standalone executable scripts directly into a local
or global command directory. Other toolkit lifecycle commands establish their
command boundaries, help systems, scope handling, and routing independently.

# 🧩 Toolkits

**Binary toolkit**

The binary toolkit manages standalone executable scripts sourced from the
`bin/` directory. It installs and uninstalls exact executable names in
`~/.local/bin` by default or `/usr/local/bin` with global scope. Its status
command compares SHA-256 checksums to report local and global state.

**Shell toolkit**

The shell toolkit manages Bash and Zsh integrations sourced from the `shell/`
directory. Installation places the integration in its designated location,
while enabling it makes the installed integration take effect.

**Configuration toolkit**

The configuration toolkit manages configuration and preference files sourced
from the `config/` directory. It installs, removes, and reports the status of
managed configuration files.

# 🔗 Relationship with Mint Provisioner

Mint Provisioner remains responsible for preparing a Linux Mint system and
installing its software dependencies. SysKit focuses on the configuration and
integration layer that follows installation.

Keeping these responsibilities in separate repositories provides clearer
project context, smaller release boundaries, and independent versioning. Mint
Provisioner can install SysKit as part of a provisioning workflow, but SysKit
does not require Mint Provisioner when installed or used independently.
