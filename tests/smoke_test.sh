#!/bin/bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bootable-installer-test.XXXXXX")
MOCK_BIN="$WORK_DIR/bin"
LOG_FILE="$WORK_DIR/commands.log"
PKG_FILE="$WORK_DIR/Install MacOSX.pkg"
ESCAPED_PKG_FILE=${PKG_FILE// /\\ }

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN"
touch "$PKG_FILE"

cat >"$MOCK_BIN/diskutil" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'diskutil %q\n' "$@" >>"$TEST_LOG"
case "$1" in
    info)
        if [[ "$2" == /Volumes/* ]]; then
            printf '   Device Identifier:        disk99s1\n'
        else
            printf '   Device Identifier:        %s\n' "$2"
        fi
        ;;
    eraseDisk)
        exit 0
        ;;
    eject)
        exit 0
        ;;
    *)
        printf 'unexpected diskutil command: %s\n' "$1" >&2
        exit 1
        ;;
esac
MOCK

cat >"$MOCK_BIN/pkgutil" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'pkgutil %q\n' "$@" >>"$TEST_LOG"
mkdir -p "$3/InstallMacOSX.pkg"
touch "$3/InstallMacOSX.pkg/Payload"
MOCK

cat >"$MOCK_BIN/tar" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'tar %q\n' "$@" >>"$TEST_LOG"
touch InstallESD.dmg
MOCK

cat >"$MOCK_BIN/hdiutil" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'hdiutil %q\n' "$@" >>"$TEST_LOG"
case "$1" in
    attach)
        image="$2"
        mountpoint=""
        while [[ $# -gt 0 ]]; do
            if [[ "$1" == "-mountpoint" ]]; then
                mountpoint="$2"
                break
            fi
            shift
        done
        mkdir -p "$mountpoint"
        if [[ "$image" == *InstallESD.dmg ]]; then
            mkdir -p "$mountpoint/Packages"
            touch "$mountpoint/BaseSystem.dmg" "$mountpoint/BaseSystem.chunklist"
        else
            mkdir -p "$mountpoint/System/Installation/Packages"
        fi
        ;;
    convert)
        output=""
        source="$2"
        while [[ $# -gt 0 ]]; do
            if [[ "$1" == "-o" ]]; then
                output="$2"
                break
            fi
            shift
        done
        if [[ "$source" == *.sparseimage ]]; then
            touch "$output"
        else
            touch "$output.sparseimage"
        fi
        ;;
    resize)
        if [[ " $* " == *" -limits "* ]]; then
            printf '0 0 1048576\n'
        fi
        ;;
    detach)
        exit 0
        ;;
    *)
        printf 'unexpected hdiutil command: %s\n' "$1" >&2
        exit 1
        ;;
esac
MOCK

cat >"$MOCK_BIN/sudo" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'sudo %q\n' "$@" >>"$TEST_LOG"
exec "$@"
MOCK

cat >"$MOCK_BIN/asr" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'asr %q\n' "$@" >>"$TEST_LOG"
source=""
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--source" ]]; then
        source="$2"
        break
    fi
    shift
done
test -f "$source"
MOCK

chmod +x "$MOCK_BIN"/*

TEST_LOG="$LOG_FILE" PATH="$MOCK_BIN:/usr/bin:/bin" \
    bash "$ROOT_DIR/create_bootable_installer.sh" <<EOF
$ESCAPED_PKG_FILE
/Volumes/Test\ USB

ERASE
EOF

grep -q 'diskutil eraseDisk' "$LOG_FILE"
grep -Fq 'MacOS\ Boot\ USB' "$LOG_FILE"
grep -q 'hdiutil attach' "$LOG_FILE"
grep -q 'asr restore' "$LOG_FILE"

last_convert_line=$(awk '/hdiutil convert/ { line=NR } END { print line }' "$LOG_FILE")
erase_line=$(awk '/diskutil eraseDisk/ { print NR; exit }' "$LOG_FILE")
if [ -z "$last_convert_line" ] || [ -z "$erase_line" ] || [ "$erase_line" -le "$last_convert_line" ]; then
    echo "Expected USB erase to happen after final image conversion" >&2
    exit 1
fi

echo "Smoke test passed"
