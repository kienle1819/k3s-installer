# Changelog

All notable changes to this project will be documented in this file.

## [1.0.3-beta.1] - 2026-06-28

### Changed
- Upgraded default K3s version to `v1.36.2+k3s1`
- Upgraded default Calico version to `v3.32.1`
- Released as a beta tag for testing and validation.


## [1.0.2] - 2026-06-28

### Added
- Added a cluster health check (`wait_for_cluster_ready`) at the end of the installation to ensure all nodes are `Ready` and system pods are fully `Running` or `Completed` before declaring success.


## [1.0.1] - 2026-06-28

### Fixed
- Fixed an issue where the script silently exits during interactive prompts when executed via `curl | bash` (redirected `read` from `/dev/tty`).

## [1.0.0] - 2026-06-28

### Added
- Initial release of the K3s installer script
- Support for installing K3s with Calico networking
- Interactive menu for install, uninstall, status, and logs
- GitHub curl-based installation instructions in the README
