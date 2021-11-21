# Alteryx PowerShell module

Alteryx PowerShell module (PSAYX) is a framework for the automation of administration tasks for Alteryx.

## Table of contents <!-- omit in TOC -->

1. [Usage](#usage)
   1. [Installation](#installation)
   2. [Import](#import)
   3. [List available functions](#list-available-functions)
2. [Dependencies](#dependencies)

## Usage

### Installation

There are two methods of setting up the Alteryx PowerShell Module on your system:

1. Download the `PSAYX` module from the [GitHub repository](https://github.com/Akaizoku/PSAYX);
2. Install the `PSAYX` module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/PSAYX).

```powershell
Install-Module -Name "PSAYX" -Repository "PSGallery"
```

### Import

```powershell
Import-Module -Name "PSAYX"
```

### List available functions

```powershell
Get-Command -Module "PSAYX"
```

| CommandType | Name                        | Version | Source |
| ----------- | --------------------------- | ------: | ------ |
| Function    | Add-AlteryxLicense          |   1.0.1 | PSAYX  |
| Function    | Backup-AlteryxDatabase      |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxInstallDirectory |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxLicense          |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxRegistryVersion  |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxServerSecret     |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxUtility          |   1.0.1 | PSAYX  |
| Function    | Get-AlteryxVersion          |   1.0.1 | PSAYX  |
| Function    | Install-AlteryxDataPackage  |   1.0.1 | PSAYX  |
| Function    | Install-AlteryxServer       |   1.0.1 | PSAYX  |
| Function    | Lock-AlteryxWorkflow        |   1.0.1 | PSAYX  |
| Function    | New-AlteryxLicenseFile      |   1.0.1 | PSAYX  |
| Function    | New-AlteryxPackage          |   1.0.1 | PSAYX  |
| Function    | Remove-AlteryxLicense       |   1.0.1 | PSAYX  |
| Function    | Reset-AlteryxLicenseServer  |   1.0.1 | PSAYX  |
| Function    | Restore-AlteryxDatabase     |   1.0.1 | PSAYX  |
| Function    | Set-AlteryxLicenseServer    |   1.0.1 | PSAYX  |
| Function    | Set-AlteryxServerSecret     |   1.0.1 | PSAYX  |
| Function    | Set-AlteryxSetting          |   1.0.1 | PSAYX  |
| Function    | Set-AlteryxSettingFile      |   1.0.1 | PSAYX  |
| Function    | Start-AlteryxWorkflow       |   1.0.1 | PSAYX  |
| Function    | Test-AlteryxSettingFile     |   1.0.1 | PSAYX  |
| Function    | Uninstall-AlteryxServer     |   1.0.1 | PSAYX  |

## Dependencies

This module depends on the usage of functions provided by the [PowerShell Tool Kit (PSTK)](https://www.powershellgallery.com/packages/PSTK/) module (version 1.2.4).
