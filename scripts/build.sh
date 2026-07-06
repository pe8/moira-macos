#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC_DIR="src/main/java"
BUILD_DIR="build"
CLASSES_DIR="$BUILD_DIR/classes"
DIST_DIR="dist"
RESOURCES_DIR="resources"
LIB_DIR="lib"
resolve_java_home() {
  local host_arch
  host_arch="$(uname -m)"
  if [[ -n "${MOIRA_JAVA_HOME:-}" ]]; then
    printf '%s\n' "$MOIRA_JAVA_HOME"
  elif [[ -n "${JAVA_HOME:-}" ]]; then
    printf '%s\n' "$JAVA_HOME"
  elif [[ "$host_arch" == "arm64" && -x "$ROOT/runtime/jdk-17-aarch64/Contents/Home/bin/java" ]]; then
    printf '%s\n' "$ROOT/runtime/jdk-17-aarch64/Contents/Home"
  elif [[ -x "$ROOT/runtime/jdk-17-x64/Contents/Home/bin/java" ]]; then
    printf '%s\n' "$ROOT/runtime/jdk-17-x64/Contents/Home"
  elif command -v /usr/libexec/java_home >/dev/null 2>&1; then
    /usr/libexec/java_home -v 17+ 2>/dev/null || true
  fi
}

JAVA_HOME_RESOLVED="$(resolve_java_home)"
if [[ -z "$JAVA_HOME_RESOLVED" || ! -x "$JAVA_HOME_RESOLVED/bin/java" ]]; then
  echo "Java 17+ is required. Set MOIRA_JAVA_HOME to a Java 17+ JDK." >&2
  exit 1
fi
JAVA_CMD="${JAVA_CMD:-$JAVA_HOME_RESOLVED/bin/java}"
JAVAC_CMD="${JAVAC_CMD:-$JAVA_HOME_RESOLVED/bin/javac}"
JAVA_SPEC_VERSION="$("$JAVA_CMD" -XshowSettings:properties -version 2>&1 \
  | awk -F= '/^[[:space:]]*java.specification.version[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}')"
if [[ -z "$JAVA_SPEC_VERSION" || "${JAVA_SPEC_VERSION%%.*}" -lt 17 ]]; then
  echo "Java 17+ is required. $JAVA_CMD reports java.specification.version=$JAVA_SPEC_VERSION." >&2
  exit 1
fi
JAVA_ARCH="$("$JAVA_CMD" -XshowSettings:properties -version 2>&1 \
  | awk -F= '/^[[:space:]]*os.arch[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}')"
case "$JAVA_ARCH" in
  aarch64|arm64)
    DEFAULT_SWT_JAR="$LIB_DIR/swt-cocoa-macosx-aarch64-3.126.0.jar"
    ;;
  *)
    DEFAULT_SWT_JAR="$LIB_DIR/swt-cocoa-macosx-x86_64-3.126.0.jar"
    ;;
esac
SWT_JAR="${MOIRA_SWT_JAR:-$DEFAULT_SWT_JAR}"
JFACE_JAR="$LIB_DIR/eclipse-legacy-support.jar"
SOURCES_FILE="$BUILD_DIR/sources.txt"

rm -rf "$CLASSES_DIR" "$DIST_DIR"
mkdir -p "$CLASSES_DIR" "$DIST_DIR" "$BUILD_DIR"

find "$SRC_DIR/org/athomeprojects" -name '*.java' \
  ! -path '*/moiraApplet/*' \
  | sort > "$SOURCES_FILE"

"$JAVAC_CMD" \
  -encoding ISO-8859-1 \
  -cp "$SWT_JAR:$JFACE_JAR" \
  -d "$CLASSES_DIR" \
  @"$SOURCES_FILE"

cp -R "$RESOURCES_DIR"/. "$DIST_DIR"/
jar cfe "$DIST_DIR/moira.jar" org.athomeprojects.moira.Moira -C "$CLASSES_DIR" .

echo "Built $DIST_DIR/moira.jar using $(basename "$SWT_JAR")"
