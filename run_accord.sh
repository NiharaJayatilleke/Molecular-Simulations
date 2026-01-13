#!/bin/bash
# Run AcCoRD simulation with just the config filename
# Usage: ./run_accord.sh accord_config_sample_communication_chemical_dif_coef
#    or: ./run_accord.sh accord_config_sample_communication_chemical_dif_coef.txt

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
BIN_DIR="$SCRIPT_DIR/bin"

if [ -z "$1" ]; then
    echo "Usage: ./run_accord.sh <config_filename>"
    echo "Example: ./run_accord.sh accord_config_sample_communication_chemical_dif_coef"
    exit 1
fi

CONFIG_NAME="$1"

# Add .txt extension if not provided
if [[ ! "$CONFIG_NAME" == *.txt ]]; then
    CONFIG_NAME="${CONFIG_NAME}.txt"
fi

CONFIG_PATH="$CONFIG_DIR/$CONFIG_NAME"

# Check if config file exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: Config file not found: $CONFIG_PATH"
    echo ""
    echo "Available configs:"
    ls "$CONFIG_DIR"/*.txt 2>/dev/null | xargs -n1 basename
    exit 1
fi

echo "Running: $BIN_DIR/accord_dub.out $CONFIG_PATH"
cd "$BIN_DIR"
./accord_dub.out "$CONFIG_PATH"
