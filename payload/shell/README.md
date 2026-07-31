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
`cli_git.zsh` for Zsh.

---

# Contents

- [Bat](#bat-clibat)
- [Eza](#eza-clieza)
- [Git](#git-cligit)
- [Oh My Posh](#oh-my-posh-termoh-my-posh)
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

---

# Oh My Posh (`term/oh-my-posh`)

Provides separate Bash and Zsh initialization payloads. Each payload evaluates
the shell-specific output from `oh-my-posh init`.

The corresponding configuration module can install either integration and
activate either SysKit shell loader. It treats Starship as mutually exclusive
and skips installation when Starship is detected unless `--force` is used.

---

# Starship (`term/starship`)

Provides separate Bash and Zsh initialization payloads for Starship. Both
payloads add a blank line before every prompt except the first prompt in a
shell session, then initialize Starship for the selected shell.

The corresponding configuration module sets `add_newline = false` through
Starship's own configuration editor so Starship does not add a second blank
line. Its uninstall workflow restores `add_newline = true` and delegates shell
payload removal to the corresponding SysKit shell command.

The configuration module treats Oh My Posh as mutually exclusive and skips
installation when Oh My Posh is detected unless `--force` is used.

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
