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

Configuration and shell install/uninstall commands resolve module arguments
through `lib/common/resolver.sh`. A caller supplies its own category/module
root, so resolution cannot cross from configuration modules into shell
payloads or vice versa. An exact canonical ID is accepted directly; otherwise,
a unique module-name segment is resolved to its canonical ID. Zero matches
return status `1`, while multiple matches return status `2`. Internal aliases
are consulted only after direct resolution fails, and an alias target must
still be a valid, existing canonical ID under the caller's root.

Configuration modules have their own directory contract, metadata format, and
lifecycle rules. See the
[configuration module guide](config/modules/README.md) for details.
