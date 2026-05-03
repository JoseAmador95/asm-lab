#!/bin/bash
set -e

DEBUG_MODE=false
LAB_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        *)
            LAB_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$LAB_FILE" ]]; then
    echo "Usage: $0 [--debug] <lab_file.s>"
    echo "Example: $0 --debug labs/lab1/lab1.s"
    exit 1
fi

if [[ ! -f "$LAB_FILE" ]]; then
    echo "Error: Lab file $LAB_FILE not found."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$SCRIPT_DIR"
LINKER_SCRIPT="$COMMON_DIR/linker.ld"
STARTUP_SCRIPT="$COMMON_DIR/startup.s"

for tool in arm-none-eabi-as arm-none-eabi-ld qemu-system-arm; do
    if ! command -v $tool &> /dev/null; then
        echo "Error: $tool not installed. Install arm-none-eabi-gcc and qemu."
        exit 1
    fi
done

if [[ ! -f "$LINKER_SCRIPT" ]]; then
    echo "Error: Linker script $LINKER_SCRIPT not found."
    exit 1
fi
if [[ ! -f "$STARTUP_SCRIPT" ]]; then
    echo "Error: Startup script $STARTUP_SCRIPT not found."
    exit 1
fi

LAB_BASENAME=$(basename "$LAB_FILE" .s)
LAB_DIR=$(dirname "$LAB_FILE")
OBJ_FILE="$LAB_DIR/$LAB_BASENAME.o"
STARTUP_OBJ="$COMMON_DIR/startup.o"
SEMIHOSTING_OBJ="$COMMON_DIR/semihosting.o"
SEMIHOSTING_SCRIPT="$COMMON_DIR/semihosting.s"
ELF_FILE="$LAB_DIR/$LAB_BASENAME.elf"

echo "Assembling startup script..."
arm-none-eabi-as -mcpu=cortex-m3 -mthumb -g -o "$STARTUP_OBJ" "$STARTUP_SCRIPT"

echo "Assembling semihosting helpers..."
arm-none-eabi-as -mcpu=cortex-m3 -mthumb -g -o "$SEMIHOSTING_OBJ" "$SEMIHOSTING_SCRIPT"

echo "Assembling $LAB_FILE..."
arm-none-eabi-as -mcpu=cortex-m3 -mthumb -g -o "$OBJ_FILE" "$LAB_FILE"

echo "Linking object files..."
arm-none-eabi-ld -T "$LINKER_SCRIPT" -o "$ELF_FILE" "$STARTUP_OBJ" "$SEMIHOSTING_OBJ" "$OBJ_FILE"

if $DEBUG_MODE; then
    if ! command -v arm-none-eabi-gdb &> /dev/null; then
        echo "Error: arm-none-eabi-gdb not installed. Required for debug mode."
        exit 1
    fi
    echo "Verifying debug info..."
    if ! arm-none-eabi-readelf -S "$ELF_FILE" | grep -q debug; then
        echo "Warning: No debug info found in $ELF_FILE."
    fi
    echo "Starting QEMU in debug mode (halted, GDB stub on :1234)..."
    qemu-system-arm -machine lm3s6965evb -cpu cortex-m3 -kernel "$ELF_FILE" -nographic -semihosting -monitor stdio -s -S &
    QEMU_PID=$!
    sleep 1
    echo "Launching arm-none-eabi-gdb..."
    arm-none-eabi-gdb -ex "target remote localhost:1234" -ex "file $ELF_FILE" -ex "break Reset_Handler" -ex "continue"
    kill $QEMU_PID 2>/dev/null || true
else
    echo "Running $ELF_FILE on QEMU (lm3s6965evb)..."
    qemu-system-arm -machine lm3s6965evb -cpu cortex-m3 -kernel "$ELF_FILE" -nographic -semihosting
fi
