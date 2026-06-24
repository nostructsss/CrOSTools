# ChromeOS Flex Deployment Image Builder

An enterprise-grade automation script to securely fetch, cache, and inject Google Admin enrollment tokens into ChromeOS Flex mass-deployment images (`.bin`). 

This tool eliminates the manual overhead of configuring cloud-readiness deployment states for bulk hardware provisioning.

## Features

- **Automated Dependency Injection:** Checks for, verifies, and installs `cros-flex-tools` along with security prerequisites (`curl`, `gpg`) seamlessly.
- **Fail-Safe Execution:** Employs Bash `set -euo pipefail` to ensure the runtime halts safely if any background pipe or command encounters a failure.
- **Workspace Isolation:** Maintains clean, configurable segregation between large image caching paths and final production packages.
- **Robust Argument Parsing:** Validates missing parameters, unexpected flags, or empty variable assertions prior to starting resource-heavy operations.

## Architecture & Workflow

The script manages structural file migrations across isolated environments to optimize caching and avoid image corruption:

[Google/ChromeOS Repos]
│
▼ (download_flex_image)

 1. Download Workspace (~5-30+GB)  ───► Caches base image (automatic_enrollment_image.bin)
    (Tested with 32GB image on   
    a 128GB SSD Debian Machine)                                   
│
▼ (cp to safe environment)

 2. Package Workspace             ───► In-place modification (package_flex_image --enrollment_token)
│
▼
[Final Provisioned Image ready for USB flashing]

## Prerequisites

The utility is built for Debian/Ubuntu-based environments (or any environment supporting the `apt` package manager). It requires root privileges (`sudo`) to manage keyrings and fetch enterprise deployment tools.

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/nostructsss/chromeos-flex-builder.git](https://github.com/nostructsss/chromeos-flex-builder.git)
   cd chromeos-flex-builder

2. **Make the script executable:**
   ```bash
   chmod +x deploy_cros.sh

3. **Usage and Configuration Options:**
    ```bash
    sudo ./build-flex-image.sh --token <YOUR_ENROLLMENT_TOKEN> [OPTIONS]
