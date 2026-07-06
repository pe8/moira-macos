# moira-macos

macOS port of Moira, a Chinese astrology charting program.

## Run from source

```bash
./scripts/build.sh
./scripts/run.sh
```

The launcher must use `-XstartOnFirstThread` for SWT on macOS. The scripts
select the bundled SWT jar from the architecture of the Java runtime:

- `x86_64`: `lib/swt-cocoa-macosx-x86_64-3.111.0.jar`
- `aarch64` / `arm64`: `lib/swt-cocoa-macosx-aarch64-3.122.0.jar`

You can override the runtime and SWT jar if needed:

```bash
JAVA_CMD=/path/to/java JAVAC_CMD=/path/to/javac ./scripts/build.sh
MOIRA_SWT_JAR=lib/swt-cocoa-macosx-x86_64-3.111.0.jar ./scripts/run.sh
```

## Notes

- Java 8 is the currently verified runtime for the Intel build.
- Build output is written to `build/` and `dist/`; both are ignored by git.
- Original Moira source files are GPL-licensed as noted in their headers.

