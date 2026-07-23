# 📦 SysKit Binary Assets

This directory stores standalone executable scripts managed by the SysKit
binary toolkit.

Each installable executable is an extensionless regular file directly inside
this directory. Executable permission in the repository is optional because
installation always sets mode `0755`. Subdirectories and companion payloads are
not supported. The executable name `all` is reserved by the install command.

Local installation uses `~/.local/bin`, while global installation uses
`/usr/local/bin`. Command routing and implementation live under `lib/bin/`.

# Table of Content

- [`mkvmerge-extract-info`](#mkvmerge-extract-info)
- [`mkvmerge-process`](#mkvmerge-process)
- [`organize-files-by-date`](#organize-files-by-date)

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
