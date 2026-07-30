# ⚙️ SysKit Configuration Assets

This directory stores configuration and preference assets managed by the
SysKit configuration toolkit.

Assets mirror their configuration module's canonical ID:

```text
payload/config/<category>/<module>/
```

The corresponding lifecycle logic lives under:

```text
command/config/modules/<category>/<module>/
```

## Terminal Assets

### Ghostty (`term/ghostty`)

Provides `syskit.ghostty`, which configures the GitHub Dark theme, disables
window-state restoration, and defines split creation, navigation, and zoom
shortcuts.

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
installation. Running `syskit-cfg install --force <category/module>` allows
their file-install action to overwrite existing targets.
