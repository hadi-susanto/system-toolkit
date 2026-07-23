# Mint Provisioner Agent Guidelines

## General Guidelines

- Use Bash with `#!/usr/bin/env bash`.
- Every executable entrypoint and module phase script must enable strict mode immediately after the shebang using `set -euo pipefail`.
- Sourced libraries, helpers, and shell-integration payloads must not change the caller's shell options. They must remain compatible with `set -euo pipefail`.
- Quote variable expansions unless word splitting or pathname expansion is intentional.
- Use `1` and `0` for internal Boolean variables and associative-array options.
  Use `true` and `false` strings only for Boolean values originating from
  environment variables, such as `FEATURE_ENABLE`.
- Use guard clauses and avoid unnecessary nesting.
- Prefer small, readable validation appropriate for this framework.
- Use `NON_INTERACTIVE`, never `NONINTERACTIVE`.
- Module canonical IDs use the `<category>/<module>` format.
- Preserve unrelated user changes in the working tree.
- Prefer (( ... )) for arithmetic conditions and numeric boolean flags. Prefer [[ ... ]] for string comparisons, pattern matching, and filesystem tests.

## Safety

- Do not run `sudo` unless explicitly requested.
- Do not run installation phases that modify the operating system during validation.
- Do not install packages, add APT repositories, modify services, or write under `/etc`, `/usr`, `/opt`, or other system directories unless explicitly requested.
- Prefer syntax checks, static analysis, mocks, temporary directories, and isolated test fixtures.
- Do not commit, push, merge, or modify unrelated files unless requested.

## Function Documentation

- Document public or reusable Bash functions with a concise comment block.
- Documentation should include, when applicable:
  - A short description
  - Parameters
  - Output written to stdout
  - Non-zero return behavior
- Do not document `return 0` when success is the function's only normal return behavior.
- Functions prefixed with `__` are private helpers.
- Private helpers do not require documentation when their purpose is clear from their name and implementation.
- Document a private helper when its behavior, parameters, output, or return codes are not obvious.

Example:

```bash
##
# resolve_package <toolkit>
#
# Resolves a UI toolkit name to its corresponding package.
#
# Parameters:
#   toolkit    Supported toolkit name.
#
# Output:
#   Prints the resolved package name.
#
# Returns:
#   1 when the toolkit is unsupported.
#
resolve_package() {
    ...
}
```

## Variable Scope and Function Parameters

* Prefer passing values to functions as parameters instead of relying on global variables.
* Keep global variable usage to a minimum. Use globals only when the value genuinely represents shared script or framework state.
* When a global variable is intended for internal use only, prefix its name with `__` to indicate that it is private.
* Do not use a global variable merely to avoid passing a parameter.
* Prefer `local` variables inside functions unless the variable intentionally needs to affect a broader scope.

Prefer:

```bash
process_package() {
    local package="$1"

    install_package "$package"
}
```

Instead of:

```bash
PACKAGE="example"

process_package() {
    install_package "$PACKAGE"
}
```

When internal shared state is unavoidable:

```bash
__cached_package=""

resolve_package() {
    if [[ -n "$__cached_package" ]]; then
        printf '%s\n' "$__cached_package"

        return 0
    fi

    ...
}
```

## Return and Exit Statements

Place a blank line before standalone `return` and `exit` statements when they follow another statement in the same block.

Correct:

```bash
if [[ "$failed" == "1" ]]; then
    log_error "Operation failed"

    exit 1
fi
```

Incorrect:

```bash
if [[ "$failed" == "1" ]]; then
    log_error "Operation failed"
    exit 1
fi
```

Compact guard expressions are allowed when they improve clarity:

```bash
load_states "$CANONICAL_ID" || exit $?
```

## Guard Clauses

Prefer guard clauses to reduce nesting and keep the main execution path easy to follow.

Use an early `return`, `exit`, or `continue` when handling an exceptional, invalid, or skip condition before continuing with the main logic.

Example:

```bash
if [[ "${SKIP_CONFIGURATION:-false}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration"

    exit 0
fi

# Continue with the main logic.
```

Inside loops, prefer `continue` when it keeps the main processing path flat and clear:

```bash
for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    process_file "$file"
    notify "Success processing $file"
    remove_file "$file"
done
```

Do not introduce a guard clause when the conditional body contains only a single simple operation and the positive condition is easier to read directly.

Prefer:

```bash
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        process_file "$file"
    fi
done
```

Instead of:

```bash
for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    process_file "$file"
done
```

The same principle applies outside loops. Do not use an early `return` solely to avoid nesting a single simple statement.

Prefer:

```bash
if [[ "$enabled" == "1" ]]; then
    enable_feature
fi
```

Instead of:

```bash
if [[ "$enabled" != "1" ]]; then
    return 0
fi

enable_feature
```

Use judgment based on readability rather than applying guard clauses mechanically.

## Error Handling

- Check failures from operations required for the phase to succeed.
- Log a useful error before returning or exiting with a non-zero status.
- Do not log an error and then silently report success.
- Preserve meaningful exit codes from installation-detection scripts.
- Optional maintenance operations may log a warning and continue when their failure does not invalidate the installation.

## Shell Script Structure

All new executable-style shell scripts should follow a consistent entry-point structure.

* Define a `main()` function as the primary entry point.
* End the script with an explicit `main "$@"` call.
* Scripts that accept or route command-line arguments should define a private `__parse_args()` function before `main()`.
* `__parse_args()` should use an associative array to store parsed commands and options, and an indexed array for remaining positional arguments when applicable.
* Store the selected command in the `CMD` key.
* A command must not be replaced once `CMD` has been set. If parsing attempts to select another command, log an error and return `1`.
* Keep command dispatch explicit using a `case` statement in `main()`. Do not dynamically derive executable script paths from arbitrary command input.
* Scripts that do not accept command-line options or perform command routing may omit `__parse_args()`, but should still use the `main()` entry-point pattern.

Example structure:

```bash
__parse_args() {
    local -n options_ref="$1"
    local -n args_ref="$2"
    shift 2

    options_ref=(
        [CMD]=""
    )

    args_ref=()

    # Parse arguments...
}

main() {
    local -A options
    local -a args

    __parse_args options args "$@" || return $?

    case "${options[CMD]}" in
        # Explicit command handlers...
    esac
}

main "$@"
```


## Validation

After modifying Bash files:

- Run `bash -n` on every changed Bash script.
- Run ShellCheck when it is available.
- Use safe mocks or temporary directories for behavioral tests.
- Do not perform real package installation or system configuration as part of routine validation.
- Review the final diff for unrelated changes.
