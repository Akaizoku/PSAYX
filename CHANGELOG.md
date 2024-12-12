# Changelog

All notable changes to the [PSAYX](https://github.com/Akaizoku/PSAYX) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2](https://github.com/Akaizoku/PSAYX/releases/1.1.2) - 2024-12-12

Bugfix and incremental improvements

### Changed

- Update-LicenseToken: Add API error handling

## [1.1.1](https://github.com/Akaizoku/PSAYX/releases/1.1.1) - 2024-10-08

Bugfix and incremental improvements

### Changed

- Get-LatestRelease: Add Designer and Intelligence Suite support
- Get-LicensedProducts: Fix parameter name

## [1.1.0](https://github.com/Akaizoku/PSAYX/releases/1.1.0) - 2024-10-07

New installers and API support

### Added

The following functions have been added:

- Get-LatestRelease: Fetch latest release from the Alteryx license portal API
- Get-LicensedProducts: List available products from the Alteryx license portal API
- Get-ProductEditions: List available product editions from the Alteryx license portal API
- Get-ProductReleases: List available product releases from the Alteryx license portal API
- Invoke-LicenseAPI: Call the Alteryx license portal API
- Update-LicenseToken: Refresh Alteryx license portal API access token
- Invoke-ServerAPI: Call the Alteryx Server API
- Get-EMongoPassword: Returns embedded MongoDB database user and admin passwords
- Repair-Database: Run maintenance scripts to repair embedded MongoDB database
- Get-ServicePath: Return the path to the Alteryx service executable from registry
- Install-Package: Install Alteryx Data Package

### Changed

The following functions have been updated:

- Get-ServerProcess
- Get-Version: Now parse version by default (use `-Raw` parameter to get the raw output)
- Install-Server: Add support for new installers (versions 2022.3+)
- Uninstall-Server: Add support for new installers (versions 2022.3+)
- Get-License: Path to executable is now optional
- Get-InstallDirectory: Update registry key
- Get-RegistryVersion: Update registry key
- Get-Utility: Add support for more executables

### Fixed

- Add-License: Fix [Parameter Exception for LicenseKey](https://github.com/Akaizoku/alteryx-deploy/issues/20)

## [1.0.1](https://github.com/Akaizoku/PSAYX/releases/1.0.1) - 2021-11-21

Robustness improvements and bug fixes

### Added

The following functions have been added:

- Lock-Workflow

### Changed

The following functions have been updated:

- Get-ServerProcess: Function is now private; use Get-Utility instead
- Invoke-Engine: **BREAKING** `EngineVersion` parameter was removed, use `-AMP` switch instead
- Start-Workflow

### Fixed

- Get-Utility: Resolved quiproquo with licensing utilities

## [1.0.0](https://github.com/Akaizoku/PSAYX/releases/1.0.0) - 2021-09-20

First stable release

### Added

Module manifest, README, LICENSE, and CHANGELOG.
