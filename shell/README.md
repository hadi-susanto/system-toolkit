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

Shared command routing and implementation live under `lib/shell/`, while this
directory contains only the shell-specific integration assets.

## Directory Layout

Each shell integration module is stored under:

```text
shell/[module]/[files]
```

where `[module]` contains all integration assets for a single SysKit module.
The internal file layout depends on the shell adapter implementation.

### Bash

```text
shell/[module]/[module.bash]
```

or

```text
shell/[module]/[module.sh]
```

### Zsh

```text
shell/[module]/[module.zsh]
```

or

```text
shell/[module]/[module.sh]
```

Future shell adapters (such as Fish or Nushell) may define their own directory
layout and file naming conventions if required by the shell.

---

# Contents

- [Bat](#bat-bat)
- [Eza](#eza-eza)
- [Git](#git-git)

---

# Bat (`bat`)

## Exported Variables

| Variable Name | Description                                            |
|---------------|--------------------------------------------------------|
| `BAT_THEME`   | Export `BAT_THEME` = `Dracula`.                        |
| `MANPAGER`    | Export `MANPAGER` = `sh -c 'col -bx | bat -l man -p'`. |

---

# Eza (`eza`)

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

# Git (`git`)

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

## Shell Functions

| Function | Description                                                                                |
|----------|--------------------------------------------------------------------------------------------|
| `gpsup`  | Pushes the current branch to `origin` and automatically sets the upstream tracking branch. |
