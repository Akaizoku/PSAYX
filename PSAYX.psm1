<#
  .SYNOPSIS
  Alteryx PowerShell module

  .DESCRIPTION
  PowerShell library for Alteryx

  .NOTES
  File name:     PSAYX.psm1
  Author:        Florian Carrier
  Creation date: 2021-06-06
  Last modified: 2021-06-09
  Dependencies:  PowerShell Tool Kit (PSTK)

  .LINK
  https://www.powershellgallery.com/packages/PSAYX
  
  .LINK
  https://www.powershellgallery.com/packages/PSTK
#>

# Get public and private function definition files
$Public  = @( Get-ChildItem -Path "$PSScriptRoot\Public"  -Filter "*.ps1" -Recurse -ErrorAction "SilentlyContinue" )
$Private = @( Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction "SilentlyContinue" )

# Import files using dot sourcing
foreach ($File in @($Public + $Private)) {
  try   { . $File.FullName  }
  catch { Write-Error -Message "Failed to import function $($File.FullName): $PSItem" }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName