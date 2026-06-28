# Contributing to k3s-installer

First off, thank you for considering contributing to `k3s-installer`! It's people like you that make this tool better for everyone.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

- **Check if the issue has already been reported.**
- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Provide specific examples to demonstrate the steps**, such as the output of the script or the log file (`/tmp/k3s-setup-*.log`).
- **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
- **Explain which behavior you expected to see instead and why.**
- **Include details about your environment** (e.g., OS version, K3s version, Calico version).

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

- **Check if the enhancement has already been suggested.**
- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
- **Explain why this enhancement would be useful** to most users.

### Pull Requests

Please follow these steps to have your contribution considered by the maintainers:

1. **Fork the repository** and create your branch from `main`.
2. **Clone your fork locally**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/k3s-installer.git
   ```
3. **Make your changes** in the new branch.
4. **Test your changes** locally. Ensure the script runs successfully without syntax errors.
5. **Run ShellCheck**: Since this is a Bash script, it is highly recommended to use [ShellCheck](https://www.shellcheck.net/) to analyze your script for potential bugs and formatting issues.
   ```bash
   shellcheck installer.sh
   ```
6. **Commit your changes**: Write clear, concise commit messages.
   ```bash
   git commit -m "feat: description of your new feature"
   ```
7. **Push to your fork** and **Submit a Pull Request** to the `main` branch of this repository.

## Development Setup

To test the script locally without affecting your main machine, it is highly recommended to use a virtual machine or a cloud VPS (like DigitalOcean or AWS) with a fresh installation of Ubuntu (22.04/24.04/26.04) or Debian (12/13).

```bash
# Run your modified script locally
bash ./installer.sh
```

Thank you for your contributions! 🚀
