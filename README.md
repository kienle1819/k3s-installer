# k3s-installer

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Changelog](https://img.shields.io/badge/Changelog-Available-blue.svg)

A simple installer for K3s + Calico on Ubuntu/Debian systems.

## Quick install from GitHub

Run this as a regular user with sudo access.

**Install a specific stable release (Recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/kienle1819/k3s-installer/v1.0.3/installer.sh | bash
```

**Install latest development version (from main branch):**
```bash
curl -fsSL https://raw.githubusercontent.com/kienle1819/k3s-installer/main/installer.sh | bash
```

If you want to inspect the script first, download it locally and run it manually:

```bash
curl -fsSL https://raw.githubusercontent.com/kienle1819/k3s-installer/main/installer.sh -o /tmp/installer.sh
bash /tmp/installer.sh
```

## What the script does

- checks basic system requirements
- installs required packages
- installs K3s with a custom configuration
- installs Calico networking
- provides a simple menu for status, logs, and uninstall

## Requirements

- Ubuntu or Debian-based server
- a non-root user with sudo privileges
- internet access

## Usage

```bash
bash installer.sh --help
bash installer.sh --version
```

If no arguments are provided, the script starts an interactive menu.

## Uninstallation

If you no longer need K3s and want to remove it completely from your system, you can use the built-in interactive menu to uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/kienle1819/k3s-installer/main/installer.sh -o /tmp/installer.sh
bash /tmp/installer.sh
```
When the menu appears, select option **2) Uninstall K3s**.

Alternatively, you can run the default K3s uninstall script provided directly by Rancher:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

## Changelog and License

- Changelog: [CHANGELOG.md](CHANGELOG.md)
- License: [LICENSE](LICENSE)
