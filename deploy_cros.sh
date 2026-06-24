#!/usr/bin/env bash

# A utility script to download and package provisioned ChromeOS Flex deployment images.

set -euo pipefail

TOKEN=""
DOWNLOAD_WORKSPACE="${HOME}/chromeos_workspace"
PACKAGE_WORKSPACE="${HOME}/chromeos_package_workspace"

show_help()
{
    cat << EOF
Usage: build-flex-image [OPTIONS]

A utility tool to download and package provisioned ChromeOS Flex deployment images.

Options:
  -t, --token <string>              The Google Admin enrollment token (required)
  -d, --download_workspace <path>   Custom directory for large image downloads (default: ~/chromeos_workspace)
  -p, --package_workspace <path>    Custom directory for packaged assets (default: ~/chromeos_package_workspace)
  -h, --help                        Display this help message and exit

Example:
  sudo ./build-flex-image --token abcd-efgh-ijkl
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--token)
            if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                echo "Error: Option '$1' requires a non-empty token argument." >&2
                exit 1
            fi
            TOKEN="$2"
            shift 2
            ;;
        -d|--download_workspace)
            if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                echo "Error: Option '$1' requires a valid directory path." >&2
                exit 1
            fi
            DOWNLOAD_WORKSPACE="$2"
            shift 2
            ;;
        -p|--package_workspace)
            if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                echo "Error: Option '$1' requires a valid directory path." >&2
                exit 1
            fi
            PACKAGE_WORKSPACE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            show_help
            exit 1
            ;;
    esac
done

if [[ -z "$TOKEN" ]]; then
    echo "Error: Missing required parameter --token." >&2
    echo "Run with --help for options." >&2
    exit 1
fi

mkdir -p "$DOWNLOAD_WORKSPACE"
mkdir -p "$PACKAGE_WORKSPACE"

export TMPDIR="$DOWNLOAD_WORKSPACE"
export ALT_TMPDIR="$PACKAGE_WORKSPACE"

TOKEN=$(echo "$TOKEN" | tr '[:upper:]' '[:lower:]')

echo "Work directory (download):  $DOWNLOAD_WORKSPACE"
echo "Work directory (package):   $PACKAGE_WORKSPACE"
echo "Enrolling with:  $TOKEN"

echo "Checking system tools..."
sudo apt-get update && sudo apt-get install -y curl gpg

if [ ! -f /usr/share/keyrings/google.linux.gpg ]; then
    echo "Configuring Google repositories..."
    curl -fsSL https://google.com | \
      sudo gpg --dearmor --yes -o /usr/share/keyrings/google.linux.gpg
    echo "deb [signed-by=/usr/share/keyrings/google.linux.gpg] https://google.com stable main" | \
      sudo tee /etc/apt/sources.list.d/google-linux.list > /dev/null
fi

if ! command -v download_flex_image &> /dev/null; then
    echo "Installing cros-flex-tools..."
    sudo apt-get update && sudo apt-get install -y cros-flex-tools
fi

TARGET_IMAGE="$DOWNLOAD_WORKSPACE/automatic_enrollment_image.bin"

if [ ! -f "$TARGET_IMAGE" ]; then
    echo "Pulling base mass-deploy image (disk cached via TMPDIR)..."
    download_flex_image --image_type=mass-deploy --output="$TARGET_IMAGE"
else
    echo "Found existing base image. Skipping download stage."
fi

FINAL_IMAGE="$PACKAGE_WORKSPACE/automatic_enrollment_image.bin"
if [ ! -f "$FINAL_IMAGE" ]; then
    cp "$TARGET_IMAGE" "$FINAL_IMAGE"
fi

echo "Injecting provisioning token into image..."
package_flex_image --in_place --image_path="$FINAL_IMAGE" --enrollment_token="${TOKEN}"

echo "Process complete! Image ready at: $FINAL_IMAGE"