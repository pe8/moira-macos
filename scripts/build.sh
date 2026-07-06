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
JAVA_CMD="${JAVA_CMD:-java}"
JAVAC_CMD="${JAVAC_CMD:-javac}"
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
