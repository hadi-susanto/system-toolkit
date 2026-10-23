# 🐚 SysKit Shell Integration Assets

This directory stores shell integration assets used by the SysKit shell
toolkit.

Each module provides the files required to integrate with one or more shells.
Currently, SysKit supports **Bash** and **Zsh**. Support for additional shells
can be added by implementing the required shell interface (adapter) and, when
necessary, providing shell-specific integration assets.

Some shells share a compatible scripting language and can reuse the same
integration files (for example, `.sh` files shared between Bash and Zsh). Other
shells, such as Fish or Nushell, require their own syntax and therefore need
dedicated integration files. As a result, the user experience and available
features may vary between shells depending on the capabilities of the shell and
its adapter implementation.

Shared command routing and implementation live under `command/shell/`.
Reusable shell libraries and interfaces live under `lib/shell/`, while this
directory contains only the shell-specific integration assets.

## Directory Layout

Each shell integration module is stored under:

```text
payload/shell/[category]/[module]/[files]
```

The canonical module ID is `[category]/[module]`. The module directory contains
all integration assets for a single SysKit module. The internal file layout
depends on the shell adapter implementation.

Install and uninstall commands accept either the canonical ID or a unique
module-name segment. For example, both commands below select `cli/git`:

```bash
syskit-bash install git
syskit-zsh uninstall cli/git
```

Resolution is limited to this shell payload tree. If a module-name segment
exists under more than one category, callers must use its canonical ID.
Installed files and shell adapters always receive the resolved canonical ID.

### Bash

```text
payload/shell/[category]/[module]/[module.bash]
```

or

```text
payload/shell/[category]/[module]/[module.sh]
```

### Zsh

```text
payload/shell/[category]/[module]/[module.zsh]
```

or

```text
payload/shell/[category]/[module]/[module.sh]
```

Future shell adapters (such as Fish or Nushell) may define their own directory
layout and file naming conventions if required by the shell.

Installed Bash and Zsh module filenames flatten the canonical ID by replacing
`/` with `_`. For example, `cli/git` is installed as `cli_git.bash` for Bash or
`cli_git.zsh` for Zsh. Regular integrations live in `module.d`; integrations
whose command module contains a `.delayed` marker live in `delayed.d` and are
loaded after every regular integration.

---

# Contents

- [Bat](#bat-clibat)
- [Claude Code](#claude-code-miscclaude-code)
- [Eza](#eza-clieza)
- [Git](#git-cligit)
- [Pay Respects](#pay-respects-clipay-respects)
- [Mise](#mise-devmise)
- [SDKMAN!](#sdkman-devsdkman)
- [Partial CD](#partial-cd-clipartial-cd)
- [Partial Complete](#partial-complete-clipartial-complete)
- [Oh My Posh](#oh-my-posh-termoh-my-posh)
- [Powerlevel10k](#powerlevel10k-termpower-level-10k)
- [Starship](#starship-termstarship)
- [Zsh](#zsh-termzsh)

---

# Bat (`cli/bat`)

## Exported Variables

| Variable Name | Description                         |
|---------------|-------------------------------------|
| `BAT_THEME`   | Export `BAT_THEME` = `Dracula`.     |
| `MANPAGER`    | Export `MANPAGER` = `sh -c 'col -bx | bat -l man -p'`. |

## Shell Aliases

| Alias     | Description                                                        |
|-----------|--------------------------------------------------------------------|
| `bat-cat` | Runs `bat --paging=never` so output is never displayed in a pager. |

---

# Claude Code (`misc/claude-code`)

Provides one shared initialization payload for Bash and Zsh. The payload
requires the `claude` command to be installed; otherwise it logs an error and
skips activation without interrupting shell startup. When available, it
exports `DISABLE_AUTOUPDATER=1` so Claude Code skips its background
auto-update check.

The corresponding configuration module can additionally enable or disable
Claude Code's own auto-updater by setting `autoUpdaterStatus` in
`~/.claude/settings.json`, install either shell integration, or activate
either SysKit shell loader. The `claude` alias resolves to `misc/claude-code`
for both the configuration and shell toolkits.

---

# Eza (`cli/eza`)

## Shell Aliases

> **Note:** Unless otherwise specified, all aliases:
>
> * Display hidden files (`--all`)
> * Show colored output and file icons
> * Sort entries by file extension
> * List directories before files

| Alias          | Description                                                                                                                                                                                                                                         |
|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ls`           | **Expands to:** `eza --grid --color=always --icons=always --all --sort extension --group-directories-first`<br><br>Displays files in a compact grid layout.                                                                                         |
| `ls-tree`      | **Expands to:** `eza --grid --tree --color=always --icons=always --all --sort extension --group-directories-first`<br><br>Displays files and directories as a tree.                                                                                 |
| `ll`           | **Expands to:** `eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso`<br><br>Displays a detailed file listing with permissions, ownership, size, and ISO-formatted timestamps. |
| `ll-tree`      | **Expands to:** `eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso`<br><br>Displays a detailed directory tree with file metadata and ISO-formatted timestamps.        |
| `ll-size`      | **Expands to:** `eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size`<br><br>Displays a detailed file listing with an overall directory size summary.             |
| `ll-tree-size` | **Expands to:** `eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size`<br><br>Displays a detailed directory tree with an overall size summary.              |
| `ll-size-tree` | Alias of `ll-tree-size`.                                                                                                                                                                                                                            |

---

# Git (`cli/git`)

## Shell Aliases

> **Note:** These aliases provide convenient shortcuts for commonly used Git commands.

| Alias  | Description                                                                                                                             |
|--------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `gcm`  | **Expands to:** `git commit -m`<br><br>Creates a commit with the message specified on the command line.                                 |
| `gp`   | **Expands to:** `git push`<br><br>Pushes local commits to the configured remote repository.                                             |
| `gb`   | **Expands to:** `git branch`<br><br>Lists, creates, or manages local branches.                                                          |
| `gbr`  | **Expands to:** `git branch --remote`<br><br>Lists remote-tracking branches.                                                            |
| `gba`  | **Expands to:** `git branch --all`<br><br>Lists both local and remote branches.                                                         |
| `gbd`  | **Expands to:** `git branch --delete`<br><br>Deletes a fully merged local branch.                                                       |
| `gbD`  | **Expands to:** `git branch --delete --force`<br><br>Forcefully deletes a local branch, even if it has unmerged changes.                |
| `gbdr` | **Expands to:** `git branch --delete --remote`<br><br>Deletes a remote-tracking branch reference from the local repository.             |
| `gco`  | **Expands to:** `git checkout`<br><br>Switches branches or restores files from the repository.                                          |
| `gcor` | **Expands to:** `git checkout --recurse-submodules`<br><br>Checks out a branch or commit while updating submodules recursively.         |
| `gsw`  | **Expands to:** `git switch`<br><br>Switches to an existing branch.                                                                     |
| `gswc` | **Expands to:** `git switch --create`<br><br>Creates a new branch and switches to it.                                                   |
| `gf`   | **Expands to:** `git fetch`<br><br>Downloads commits, branches, and tags from the configured remote without modifying the working tree. |
| `gfo`  | **Expands to:** `git fetch origin`<br><br>Fetches updates from the `origin` remote only.                                                |
| `gwa`  | **Expands to:** `git worktree add`<br><br>Creates a new worktree.                                                                       |
| `gwl`  | **Expands to:** `git worktree list`<br><br>Lists the worktrees of the repository.                                                       |
| `gwp`  | **Expands to:** `git worktree prune`<br><br>Prunes stale worktree administrative data.                                                  |
| `gwd`  | **Expands to:** `git worktree remove`<br><br>Removes a worktree.                                                                        |
| `gwr`  | **Expands to:** `git worktree repair`<br><br>Repairs worktree administrative files.                                                     |

---

# Pay Respects (`cli/pay-respects`)

Provides separate Bash and Zsh initialization payloads for
[pay-respects](https://github.com/iffse/pay-respects). Each payload requires
the `pay-respects` command; otherwise it logs an error and skips activation
without interrupting shell startup. When available, it runs
`pay-respects <shell> --alias`, which defines the default `f` alias for
correcting the previous command and enables the command-not-found handler.
It also exports `_PR_AI_DISABLE=1` to disable pay-respects' AI suggestions
unless `_PR_AI_DISABLE` is already set.

The shell dependency check requires `pay-respects` to be installed before the
integration can be installed unless `--force` is used. There is no
corresponding configuration module.

---

# Mise (`dev/mise`)

Provides one shared initialization payload for Bash and Zsh. The payload
requires the `mise` command to be installed; otherwise it logs an error and
skips activation without interrupting shell startup.

The payload reads an optional data directory override from:

```text
~/.local/state/syskit/dev/mise/data-dir
```

When the state file holds a valid absolute path, the payload exports
`MISE_DATA_DIR` before activating Mise. An invalid (non-absolute) stored path
is reported without interrupting shell startup, and a missing state file means
Mise uses its own default data directory. The payload then evaluates `mise
activate bash` or `mise activate zsh` depending on the running shell.

The corresponding configuration module provides interactive actions to set or
remove the `MISE_DATA_DIR` override, install either shell integration, or
activate either SysKit shell loader. Mise is installed into `delayed.d` and
loaded after every regular shell module.

---

# SDKMAN! (`dev/sdkman`)

Provides one shared initialization payload for Bash and Zsh. The payload reads
the configured SDKMAN! installation directory from:

```text
~/.local/state/syskit/dev/sdkman/install-dir
```

When the state and `<SDKMAN_DIR>/bin/sdkman-init.sh` are available, the payload
exports `SDKMAN_DIR` and sources the SDKMAN! initialization script. Missing or
invalid state is reported without interrupting shell startup.

The corresponding configuration module provides interactive actions to install
the state file, install either shell integration, or activate either SysKit
shell loader. Set `SDKMAN_DIR` for a custom installation:

```bash
SDKMAN_DIR="/absolute/sdkman/path" syskit-cfg configure dev/sdkman
```

When `SDKMAN_DIR` is empty, the configuration module falls back to
`INSTALL_PATH` from the Mint Provisioner registry
(`~/.local/state/mint-provisioner/registry/dev/sdkman.registry`).
SDKMAN! is installed into `delayed.d` and loaded after every regular shell
module. Existing integrations in `module.d` move to the delayed phase when
reinstalled with `--force`.

---

# Partial CD (`cli/partial-cd`)

Provides a Bash-only completion function for `cd` and `pushd` that expands
every typed path segment as a prefix, similar to Zsh's partial path
completion. For example, `cd /mn/d/p<Tab>` completes to `/mnt/data/programs/`
when it is the only match. When several directories match (`programs` and
`posters`), Readline completes only their longest common prefix,
`/mnt/data/p`; pressing Tab again lists the candidates.

Absolute, relative, and `~` paths are supported. A trailing `/` lists the
child directories. When nothing matches, Bash falls back to its default
completion. The function replaces any existing `cd` and `pushd` completion,
including the `bash-completion` package's `CDPATH` support, so the module is
installed into `delayed.d` and loaded after every regular shell module. Zsh is
not supported because it provides this behavior natively. The shell dependency
check rejects installation for any shell other than Bash. It cannot be
installed alongside `cli/partial-complete` unless `--force` is used.

---

# Partial Complete (`cli/partial-complete`)

Bash-only variant of Partial CD that applies the same per-segment prefix
expansion to every command and alias without its own completion spec, by
registering a default completion (`complete -D`). `cd` and `pushd` keep
directory-only matching; other commands match files and directories.

Only words containing `/` or starting with `~` are expanded; everything else
uses normal Bash completion. Commands with a `bash-completion` spec (git, ssh,
...) keep it: the function calls `_completion_loader` first and drops the no-op
`_minimal` spec it registers for spec-less commands, so later Tab presses reach
this function again. Option values after `=` or `:` work because Bash splits
those words. The module is installed into `delayed.d`; another `complete -D`
registered later replaces it. Zsh is not supported. It cannot be installed
alongside `cli/partial-cd` unless `--force` is used.

---

# Oh My Posh (`term/oh-my-posh`)

Provides separate Bash and Zsh initialization payloads. Each payload evaluates
the shell-specific output from `oh-my-posh init`.

The corresponding configuration module can install either integration and
activate either SysKit shell loader. The shell dependency check prevents it
from being installed alongside Starship or Powerlevel10k for the same shell
unless `--force` is used.

---

# Powerlevel10k (`term/power-level-10k`)

Provides a Zsh-only initialization payload. The payload reads the configured
Powerlevel10k installation directory from:

```text
~/.local/state/syskit/term/power-level-10k/install-dir
```

When the state file and
`<POWERLEVEL10K_INSTALL_DIR>/powerlevel10k.zsh-theme` are available, the
payload sources the theme directly. Missing or invalid state is reported
without interrupting shell startup.

The corresponding configuration module provides interactive actions to install
the state file, install the Zsh integration, or activate the SysKit Zsh loader:

```bash
POWERLEVEL10K_INSTALL_DIR="/absolute/powerlevel10k/path" \
    syskit-cfg configure term/power-level-10k
```

Powerlevel10k is loaded in the regular shell-module order.

---

# Starship (`term/starship`)

Provides separate Bash and Zsh initialization payloads for Starship. Both
payloads add a blank line before every prompt except the first prompt in a
shell session, then initialize Starship for the selected shell.

The corresponding configuration module sets `add_newline = false` through
Starship's own configuration editor so Starship does not add a second blank
line. Its uninstall workflow restores `add_newline = true` and delegates shell
payload removal to the corresponding SysKit shell command.

The shell dependency check prevents Starship from being installed alongside Oh
My Posh or Powerlevel10k for the same shell unless `--force` is used. Prompt
integrations installed only for another shell do not conflict.

---

# Zsh (`term/zsh`)

Provides the general interactive Zsh preferences migrated from Mint
Provisioner as a Zsh-only shell integration. It configures:

- History storage and duplicate handling.
- Completion with a selectable menu.
- Editor, pager, and locale environment variables.
- User executable directories in `PATH`.
- Colored `grep` output and Emacs-style key bindings.
- Optional local customizations from `~/.zshrc.local`.

This module does not install Zsh or change the user's login shell.
