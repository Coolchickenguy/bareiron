#!/usr/bin/env bash
set -euo pipefail

REQUIRED_MAJOR=21
SERVER_JAR="${SERVER_JAR:-server.jar}"
NOTCHIAN_DIR="notchian"
NOTCHIAN_VERSION="${NOTCHIAN_VERSION:-1.21.8}"
JS_RUNTIME=""

get_java_version() {
  java -version 2>&1 | awk -F[\".] '/version/ {print $2}'
}

check_java() {
  if ! command -v java >/dev/null 2>&1; then
    echo "Java not found in PATH."
    exit 1
  fi

  local major
  major="$(get_java_version)"

  if (( major < REQUIRED_MAJOR )); then
    echo "Java $REQUIRED_MAJOR or newer required, but found Java $major."
    exit 1
  fi
}

check_wget() {
  if ! command -v wget>/dev/null 2>&1; then
    echo "Wget not found in path"
    exit 1
  fi
}

check_jq() {
  if ! command -v wget>/dev/null 2>&1; then
    echo "Jq not found in path"
    exit 1
  fi
}

prepare_notchian_dir() {
  if [[ ! -d "$NOTCHIAN_DIR" ]]; then
    echo "Creating $NOTCHIAN_DIR directory..."
    mkdir -p "$NOTCHIAN_DIR"
  fi
  cd "$NOTCHIAN_DIR"
}

dump_registries() {
  if [[ ! -f "$SERVER_JAR" ]]; then
    echo "No server.jar found (looked for $SERVER_JAR)."
	  echo "Downloading version $NOTCHIAN_VERSION (change by setting NOTCHIAN_VERSION)"
    check_wget
    check_jq

    SERVER_MANIFEST_URL="$(wget -qO- "https://piston-meta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id == \"${NOTCHIAN_VERSION}\") | .url")"
    SERVER_JAR_URL="$(wget -qO- "$SERVER_MANIFEST_URL" | jq -r ".downloads.server.url")"
    wget -O server.jar "$SERVER_JAR_URL"
  fi

  java -DbundlerMainClass="net.minecraft.data.Main" -jar "$SERVER_JAR" --all
}

detect_js_runtime() {
  if command -v node >/dev/null 2>&1; then
    JS_RUNTIME="node"
  elif command -v bun >/dev/null 2>&1; then
    JS_RUNTIME="bun"
  elif command -v deno >/dev/null 2>&1; then
    JS_RUNTIME="deno run"
  else
    echo "No JavaScript runtime found (Node.js, Bun, or Deno)."
    exit 1
  fi
}

run_js_script() {
  local script="$1"
  if [[ -z "$JS_RUNTIME" ]]; then
    detect_js_runtime
  fi
  echo "Running $script with $JS_RUNTIME..."
  $JS_RUNTIME "$script"
}

check_java
prepare_notchian_dir
dump_registries
run_js_script "../build_registries.js"
echo "Registry dump and processing complete."
