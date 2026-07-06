# moira-macos

macOS port of Moira, a Chinese astrology charting program.

This repository contains a macOS-ready source tree with bundled SWT libraries
for both Intel and Apple Silicon Macs.

## Upstream

- Project page: <https://sites.google.com/site/athomeprojects>
- Source archive used for this port: <https://drive.google.com/file/d/142wbwVKZOTGiG8nBLN-WKRFkkxDeAWaB/view>

The original Moira source files are GPL-licensed as noted in their headers.
This repository keeps the original project structure where practical and adds
macOS-specific build/run support.

## Supported Macs

- Intel Macs: verified with Java 8 x86_64 and `swt-cocoa-macosx-x86_64-3.111.0.jar`
- Apple Silicon Macs: includes `swt-cocoa-macosx-aarch64-3.122.0.jar` for arm64 Java runtimes

The scripts select the SWT jar from the architecture of the Java runtime, not
the hardware. Use an arm64 JDK on Apple Silicon for the arm64 SWT jar.

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

## Changes from the original source

- Added macOS build and run scripts.
- Bundled macOS SWT jars for Intel and Apple Silicon runtimes.
- Added macOS font fallback registration to avoid Java logical `Serif` warnings
  for missing `Times` and `Lucida Bright`.
- Fixed macOS SWT marker/rubber-band drawing paths that could crash when angle
  markers or right-click interactions were used.
- Added high-resolution toolbar/menu icon assets and fixed black icon
  backgrounds caused by legacy image handling.
- Adjusted the startup layout so the chart button and location/timezone controls
  are visible without resizing the window.

## Build outputs

Build output is written to `build/` and `dist/`; both are ignored by git.
