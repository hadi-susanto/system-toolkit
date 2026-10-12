# ⚙️ SysKit Configuration Assets

This directory stores configuration and preference assets managed by the
SysKit configuration toolkit.

Assets mirror their configuration module's canonical ID:

```text
payload/config/<category>/<module>/
```

The corresponding lifecycle logic lives under:

```text
modules/config/<category>/<module>/
```

## System Assets

### apt-fast (`sys/apt-fast`)

Provides local Bash and Zsh completion files mirrored from the apt-fast vendor
repository. The module can install either bundled file or download the
corresponding current vendor source. Existing completion targets require
`syskit-cfg configure --force apt-fast` (or the canonical `sys/apt-fast` ID)
before they can be overwritten.

## Terminal Assets

### Ghostty (`term/ghostty`)

Provides `syskit.ghostty`, which configures the 3024 Night theme, disables
window-state restoration, sets the default window size, font size, and working
directory behavior, and defines split creation, navigation, and zoom shortcuts.

The module manages an optional `config-file = ?syskit.ghostty` include inside
`~/.config/ghostty/config.ghostty`. Its status compares the installed asset
with this source file and reports when an update is available.

### Kitty (`term/kitty`)

Provides:

- `syskit.kitty` for layouts, split management, window behavior, and update
  preferences.
- `syskit.session` for the default OS window state.

The module manages `globinclude syskit.kitty` inside
`~/.config/kitty/kitty.conf`. It reports the two payload files independently,
including checksum-based update availability.

Both terminal modules preserve existing payload targets during normal
installation. Running `syskit-cfg configure --force kitty` (or `syskit-cfg
kitty --force`, or the canonical `term/kitty` ID) allows the file-install
action to overwrite existing targets. The same applies to Ghostty. File
uninstallation removes the installed payload files without a checksum check.
