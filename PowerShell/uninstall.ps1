#Requires -Version 5
#Requires -RunAsAdministrator

param (
    [string] $configPath = "$PSScriptRoot\configuration.json",
    [switch] $AcceptLicense
)

Import-Module "$PSScriptRoot\confighelper.psm1"

$configuration = Format-ConfigurationFileToHashTable $configPath

# AMT
if ($configuration.uninstallAMT){
    $parameters = @{
        databasesConfig          = $configuration.databasesConfig
        amtDownloadPath          = $configuration.amtConfig.amtDownloadPath
        amtInstallerPath         = $configuration.amtConfig.amtInstallerPath
        amtOptions               = $configuration.amtConfig.options
        version                  = $configuration.amtConfig.version
    }
    Import-Module -Force "$PSScriptRoot\Applications\AMT.psm1"
    Write-Host "Uninstalling AMT..." -ForegroundColor Cyan
    Uninstall-amt @parameters
    Write-Host "AMT has been uninstalled" -ForegroundColor Cyan
}

