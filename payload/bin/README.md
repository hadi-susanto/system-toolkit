# 📦 SysKit Binary Assets

This directory stores standalone executable scripts managed by the SysKit
binary toolkit.

Each installable executable is an extensionless regular file directly inside
this directory. Executable permission in the repository is optional because
installation always sets mode `0755`. Subdirectories and companion payloads are
not supported. The executable name `all` is reserved by the install command.

Local installation uses `~/.local/bin`, while global installation uses
`/usr/local/bin`. Command routing and implementation live under
`command/bin/`, while reusable helpers live under `lib/bin/`.

# Table of Content

- [`bat-help`](#bat-help)
- [`git-bat-diff`](#git-bat-diff)
- [`git-delta-diff`](#git-delta-diff)
- [`mkvmerge-extract-info`](#mkvmerge-extract-info)
- [`mkvmerge-process`](#mkvmerge-process)
- [`organize-files-by-date`](#organize-files-by-date)

# `bat-help`

Displays command help output using Bat syntax highlighting.

When a command is provided, `bat-help` appends `--help` to the command and its
arguments. When no command is provided, it reads help text from standard input.

Requires `bat`. The supplied command must also be available in `PATH`.

Display Git help received through standard input:

```bash
git --help | bat-help
```

Run a command with `--help` appended:

```bash
bat-help git
bat-help docker run
bat-help cargo build
```

Use `--` when the command name could be interpreted as a `bat-help` option:

```bash
bat-help -- command-name
```

## Options

| Option       | Description                                                                  |
|--------------|------------------------------------------------------------------------------|
| `-h, --help` | Print usage information and exit.                                            |
| `--`         | Stop parsing `bat-help` options and treat the remaining values as a command. |

## Environment Variables

| ENV           | Description                                                                                                  |
|---------------|--------------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored help and error labels when set to a non-empty value. Default: unset.                         |
| `FORCE_COLOR` | Enable colors when output is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset.    |

---

# `git-bat-diff`

Displays files with unstaged Git changes using Bat's diff highlighting.

The command processes tracked files relative to the current working directory.
Deleted files are excluded.

Requires `git`, `bat`, and `xargs`. The command must be run inside a Git working
tree.

```bash
git-bat-diff
```

## Options

| Option       | Description                       |
|--------------|-----------------------------------|
| `-h, --help` | Print usage information and exit. |
| `--`         | Stop parsing command options.     |

## Environment Variables

| ENV           | Description                                                                                                  |
|---------------|--------------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored help and error labels when set to a non-empty value. Default: unset.                         |
| `FORCE_COLOR` | Enable colors when output is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset.    |

---

# `git-delta-diff`

Displays Git differences using Delta.

Unrecognized arguments are forwarded directly to `git diff`. Delta navigation
and `zdiff3` merge-conflict formatting are always enabled. Dark mode,
side-by-side display, and line numbers can be enabled independently.

Requires `git` and `delta`. The command must be run inside a Git working tree.

Display unstaged differences:

```bash
git-delta-diff
```

Enable dark and side-by-side display:

```bash
git-delta-diff --dark --side
```

Display staged differences with line numbers:

```bash
git-delta-diff --line-numbers --staged
```

Compare revisions:

```bash
git-delta-diff --dark HEAD~1
git-delta-diff --side main..feature
```

Restrict the comparison to specific paths:

```bash
git-delta-diff --dark -- src/main.sh
```

## Options

| Option           | Description                                                                           |
|------------------|---------------------------------------------------------------------------------------|
| `--dark`         | Enable Delta's dark color mode. Default: disabled.                                    |
| `--side`         | Display differences side by side. Default: disabled.                                  |
| `--line-numbers` | Display line numbers. Default: disabled.                                              |
| `-h, --help`     | Print usage information and exit.                                                     |
| `--`             | Stop parsing tool options and pass the separator and remaining arguments to Git Diff. |

All other arguments are forwarded directly to `git diff`.

## Environment Variables

| ENV           | Description                                                                                               |
|---------------|-----------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored help and error labels when set to a non-empty value. Default: unset.                      |
| `FORCE_COLOR` | Enable colors when output is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset. |

---

# `mkvmerge-extract-info`

Prints track information for one media file or all matching files in a
directory. The output includes track IDs, types, languages, names, and enabled,
default, and forced flags.

Requires `mkvmerge` and `jq`.

```bash
mkvmerge-extract-info --input movie.mkv
```

To process multiple file types in a directory:

```bash
mkvmerge-extract-info \
    --input movies \
    --extension mkv \
    --extension mp4
```

## Options

| Option                  | Description                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------|
| `-i, --input FILE\|DIR` | File or directory to inspect. Default: current directory (`.`).                                           |
| `-e, --extension EXT`   | File extension to include when the input is a directory. May be specified multiple times. Default: `mkv`. |
| `-h, --help`            | Print usage information and exit.                                                                         |

## Environment Variables

| ENV           | Description                                                                                               |
|---------------|-----------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored status icons when set to a non-empty value. Default: unset.                               |
| `FORCE_COLOR` | Enable colors when output is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset. |

---

# `mkvmerge-process`

Processes one media file or all matching files in a directory using
`mkvmerge`. Other arguments are forwarded to `mkvmerge`, and multiple values
following the same option cause that option to be repeated.

The generated `mkvmerge` commands are printed in preview mode by default.
Use `--apply` to execute them.

Requires `mkvmerge`.

Preview processing a single file:

```bash
mkvmerge-process \
    --input movie.mkv \
    --default 0:true
```

Apply the changes:

```bash
mkvmerge-process \
    --input movie.mkv \
    --default 0:true \
    --apply
```

Preview processing multiple file types in a directory:

```bash
mkvmerge-process \
    --input movies \
    --extension mkv \
    --extension mp4 \
    --language eng jpn
```

## Options

| Option                  | Description                                                                                                   |
|-------------------------|---------------------------------------------------------------------------------------------------------------|
| `-i, --input FILE\|DIR` | File or directory to process. Default: current directory (`.`).                                               |
| `-o, --output DIR`      | Directory for processed files. Default: an `output` directory inside the input directory.                     |
| `-e, --extension EXT`   | File extension to include when the input is a directory. May be specified multiple times. Default: `mkv`.     |
| `-d, --default`         | Shorthand for the `mkvmerge` option `--default-track-flag`.                                                   |
| `-f, --forced`          | Shorthand for the `mkvmerge` option `--forced-display-flag`.                                                  |
| `-a, --apply`           | Execute the generated `mkvmerge` commands. Without this option, only a preview is printed. Default: disabled. |
| `-h, --help`            | Print usage information and exit.                                                                             |

## Environment Variables

| ENV           | Description                                                                                                       |
|---------------|-------------------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored error labels when set to a non-empty value. Default: unset.                                       |
| `FORCE_COLOR` | Enable colors when standard error is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset. |

---

# `organize-files-by-date`

Organizes files using a `YYYYMMDD` date found in each filename. Matching files
are copied into corresponding `YYYY-MM-DD` directories by default, or moved
when `--move` is used.

Additional digits may follow the date, allowing timestamps such as
`YYYYMMDDHHMMSS`.

Preview the planned copies:

```bash
organize-files-by-date --input photos
```

Copy the matching files:

```bash
organize-files-by-date \
    --input photos \
    --apply
```

Move the matching files:

```bash
organize-files-by-date \
    --input photos \
    --apply \
    --move
```

## Options

| Option            | Description                                                                                                                         |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `-i, --input DIR` | Directory to process. Default: current directory (`.`).                                                                             |
| `-a, --apply`     | Apply the planned changes. Matching files are copied by default. Without this option, only a preview is printed. Default: disabled. |
| `-m, --move`      | Move matching files instead of copying them. Requires `--apply` and does not enable it automatically. Default: disabled.            |
| `-h, --help`      | Print usage information and exit.                                                                                                   |

## Environment Variables

| ENV           | Description                                                                                               |
|---------------|-----------------------------------------------------------------------------------------------------------|
| `NO_COLOR`    | Disable colored status icons when set to a non-empty value. Default: unset.                               |
| `FORCE_COLOR` | Enable colors when output is not connected to a terminal. Ignored when `NO_COLOR` is set. Default: unset. |
