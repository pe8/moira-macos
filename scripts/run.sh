#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DIST_DIR="dist"
LIB_DIR="lib"
JAVA_CMD="${JAVA_CMD:-java}"
JAVA_ARCH="$("$JAVA_CMD" -XshowSettings:properties -version 2>&1 \
  | awk -F= '/^[[:space:]]*os.arch[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}')"
case "$JAVA_ARCH" in
  aarch64|arm64)
    DEFAULT_SWT_JAR="$LIB_DIR/swt-cocoa-macosx-aarch64-3.122.0.jar"
    ;;
  *)
    DEFAULT_SWT_JAR="$LIB_DIR/swt-cocoa-macosx-x86_64-3.111.0.jar"
    ;;
esac
SWT_JAR="${MOIRA_SWT_JAR:-$DEFAULT_SWT_JAR}"
JFACE_JAR="$LIB_DIR/eclipse-legacy-support.jar"

if [[ ! -f "$DIST_DIR/moira.jar" ]]; then
  ./scripts/build.sh
fi

exec "$JAVA_CMD" \
  -XstartOnFirstThread \
  -cp "$DIST_DIR/moira.jar:$SWT_JAR:$JFACE_JAR" \
  org.athomeprojects.moira.Moira \
  "$DIST_DIR"
