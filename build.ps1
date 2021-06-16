# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.SYNOPSIS
    This builds a Starter Kit virtual machine using Packer
.DESCRIPTION
    Configures Packer logging, Defines a network adapter and vm switch,
    compresses equity PowerShell scripts, and intitiates the packer build.
.EXAMPLE
    PS C:\> .\build.ps1
    Creates a virtual machine image that can be imported using the Hyper-V Manager
.NOTES
    Sets the Packer debug mode and logging path variables at runtime.
#>

param([string] $vmSwitch, [string] $isoUrl)

#Requires -RunAsAdministrator
#Requires -Version 5

# Configure runtime envvars to log in debug mode
$env:PACKER_LOG = 1
$env:PACKER_LOG_PATH = ".\packer.log.txt"

# Get the first physical network adapter that has an Up status.
$net_adapter = ((Get-NetAdapter -Name "*" -Physical) | ? { $_.Status -eq 'Up'})[0].Name

if($vmSwitch -eq "") {
  # This is the name of the Hyper-V VM switch that Packer creates by default
  $vmSwitch = "packer-hyperv-iso"
}

Write-Output "Checking for existence of VM Switch $($vmSwitch)"
if ($null -eq (Get-VMSwitch -Name $vmSwitch -ErrorAction SilentlyContinue)) {
  Write-Output "Creating new VM Switch $($vmSwitch)"
  New-VMSwitch -Name $vmSwitch -AllowManagementOS $true -NetAdapterName $net_adapter -MinimumBandwidthMode Weight
}

# Compress our PowerShell to a zip archive
Compress-Archive -Path .\PowerShell -Destination .\Equity-Starter-Kit.zip -Force

Compress-Archive -Path '.\EquityModels\Equity Starter Kit.pbix' -DestinationPath .\Equity-Starter-Kit -Update

Compress-Archive -Path '.\EquityModels\Equity Views Script.sql' -DestinationPath .\Equity-Starter-Kit -Update

# Kick off the packer build with the force to override prior builds
if($isoUrl -eq "") {
  & packer build -force -var "vm_switch=$($vmSwitch)" .\Packer\equity-starter-kit-win2019-eval.json
} else {
  & packer build -force -var "vm_switch=$($vmSwitch)" -var "iso_url=$($isoUrl)" .\Packer\equity-starter-kit-win2019-eval.json
}
