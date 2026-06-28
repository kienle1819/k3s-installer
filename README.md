<div align="center">
  <h1>🚀 k3s-installer</h1>

  <p>
    <a href="https://github.com/kienle1819/k3s-installer/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT"></a>
    <a href="https://github.com/kienle1819/k3s-installer/blob/main/CHANGELOG.md"><img src="https://img.shields.io/badge/Changelog-Available-blue.svg?style=for-the-badge" alt="Changelog"></a>
    <a href="https://github.com/kienle1819/k3s-installer/releases/latest"><img src="https://img.shields.io/github/v/release/kienle1819/k3s-installer?style=for-the-badge" alt="Latest Release"></a>
  </p>

  <p><b>A simple, robust installer for K3s + Calico on Ubuntu/Debian systems.</b></p>
</div>

---

## ⚡ Quick install from GitHub

Run this as a regular user with `sudo` access.

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

## 🛠️ What the script does

- ✅ Checks basic system requirements
- ✅ Installs required packages
- ✅ Installs K3s with a custom configuration
- ✅ Installs Calico networking
- ✅ Provides a simple interactive menu for status, logs, and uninstall

## 📋 Requirements

- Ubuntu (22.04, 24.04, 26.04) or Debian (12, 13) based server
- A non-root user with `sudo` privileges
- Internet access

## 💻 Usage

```bash
bash installer.sh --help
bash installer.sh --version
```

If no arguments are provided, the script starts an interactive menu.

## 🗑️ Uninstallation

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

## 💙 Recommended Hosting: DigitalOcean

DigitalOcean is a cloud services platform delivering the simplicity developers love and businesses trust to run production applications at scale. It provides highly available, secure, and scalable compute, storage, and networking solutions that help developers build great software faster.

If you are new to DigitalOcean, you can get a **free $200 credit** to test this script by signing up through the link below:

👉 **[Deploy to DigitalOcean & Get $200 Free Credit](https://m.do.co/c/6f5dc93276b4)**

## 📖 Introduction to Bash Scripting

This project is heavily driven by Bash scripting to automate the Kubernetes setup process. If you want to learn the basics of Bash scripting and start writing awesome scripts to automate your daily tasks, we highly recommend this open-source guide:

- **[Introduction to Bash Scripting Guide/eBook](https://github.com/bobbyiliev/introduction-to-bash-scripting)** by Bobby Iliev

You can read it directly on GitHub or download it for free in various formats:
- [📥 Download Dark Mode PDF](https://github.com/bobbyiliev/introduction-to-bash-scripting/raw/main/ebook/en/export/introduction-to-bash-scripting-dark.pdf)
- [📥 Download Light Mode PDF](https://github.com/bobbyiliev/introduction-to-bash-scripting/raw/main/ebook/en/export/introduction-to-bash-scripting-light.pdf)
- [📥 Download ePub](https://github.com/bobbyiliev/introduction-to-bash-scripting/raw/main/ebook/en/export/introduction-to-bash-scripting.epub)

Other useful resources:
- [Shellcheck](https://www.shellcheck.net/) - An essential linting tool that we use to ensure the script is free of bugs.

## 📝 Changelog and License

- Changelog: [CHANGELOG.md](CHANGELOG.md)
- License: [LICENSE](LICENSE)
