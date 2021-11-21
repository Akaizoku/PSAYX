# Changelog

All notable changes to the [PSAYX](https://github.com/Akaizoku/PSAYX) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1](https://github.com/Akaizoku/PSAYX/releases/1.0.1) - 2021-11-21

Robustness improvements and bug fixes

### Added

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
