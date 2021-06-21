<#
.SYNOPSIS
    Installs the Starter Kit and all applications needed to run it.

.DESCRIPTION
    Imports each of the Ed-Fi ODS applications needed to run the Equity Starter Kit.

.EXAMPLE
    PS C:\LOCATION_OF_PACKAGE> .\install.ps1 -configPath .\path_to.json

    Downloads and installs the AdminApp, EdfiDbs, ODS API, and Swagger UI PowerShell installers for SQL Server

.INPUTS
    JSON configuration file
.NOTES
    Requires
    * SQL Server 2019
    * SQL SERVER MANAGEMENT STUDIO
    * IIS
#>

#Requires -Version 5
#Requires -RunAsAdministrator

param (
    [string] $configPath = "$PSScriptRoot\configuration.json"
)

$AppCommonVersion = "1.0.3"

#--- IMPORT MODULES FOR EdFiSuite individual modules ---
Import-Module -Force "$PSScriptRoot\Applications\EdFi-Admin.psm1"
Import-Module -Force "$PSScriptRoot\Applications\EdFi-DBs.psm1"
Import-Module -Force "$PSScriptRoot\Applications\EdFi-Swagger.psm1"
Import-Module -Force "$PSScriptRoot\Applications\EdFi-WebAPI.psm1"

#--- IMPORT MODULES FOR OUR STARTER KIT ODS APPS ---
Import-Module -Force "$PSScriptRoot\Applications\BulkLoadClient.psm1"
Import-Module -Force "$PSScriptRoot\Applications\AMT.psm1"
Import-Module -Force "$PSScriptRoot\confighelper.psm1"
Import-Module -Force "$PSScriptRoot\Applications\nuget-helper.psm1"
Import-Module -Force "$PSScriptRoot\utilities.psm1"
Import-Module -Force "$PSScriptRoot\Applications\multi-instance-helper.psm1"

$configuration = Format-ConfigurationFileToHashTable $configPath

$downloadPath = "C:\temp\downloads"
$toolsPath = "C:\temp\tools"

function Install-NugetCli {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $toolsPath,
        [string] $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/v5.3.1/nuget.exe"
    )

    if (-not $(Test-Path $toolsPath)) {
        mkdir $toolsPath | Out-Null
    }

    $nuget = (Join-Path $toolsPath "nuget.exe")

    if (-not $(Test-Path $nuget)) {
        Write-Host "Downloading nuget.exe official distribution from " $sourceNugetExe
        Invoke-WebRequest $sourceNugetExe -OutFile $nuget
    }
    else {
        $info = Get-Command $nuget
        Write-Host "Found nuget exe in: $toolsPath"

        if ("5.3.1.0" -ne $info.Version.ToString()) {
            Write-Host "Updating nuget.exe official distribution from " $sourceNugetExe
            Invoke-WebRequest $sourceNugetExe -OutFile $nuget
        }
    }
}

function Install-SqlServerModule {

    if (-not (Get-Module -ListAvailable -Name SqlServer -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | out-host
        Install-Module SqlServer -Force -AllowClobber -Confirm:$false | out-host
    }

    Import-Module SqlServer
}

function Install-AppCommonInstaller {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $toolsPath,
        [Parameter(Mandatory = $true)]
        [string] $downloadPath,
        [Parameter(Mandatory = $true)]
        [string] $version
    )
    $packageName = "EdFi.Installer.AppCommon"

    $installerPath = Install-EdFiPackage $packageName $version $toolsPath $downloadPath

    return $installerPath
}

function Set-ApiUrl {
    Param(
        [String] $expectedWebApiBaseUri
    )
    if ([string]::IsNullOrEmpty($configuration.adminAppConfig.odsApi.apiUrl)) {
        $configuration.adminAppConfig.odsApi.apiUrl = $expectedWebApiBaseUri
    }

    if ([string]::IsNullOrEmpty($formattedConfig.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl)) {
        $configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl = "$expectedWebApiBaseUri/metadata/"
    }

    if ([string]::IsNullOrEmpty($formattedConfig.swaggerUIConfig.swaggerAppSettings.apiVersionUrl)) {
        $configuration.swaggerUIConfig.swaggerAppSettings.apiVersionUrl = $expectedWebApiBaseUri
    }
}

Install-NugetCli $toolsPath

Install-SqlServerModule

$Pass = ConvertTo-SecureString -String "edfi" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "edfi", $Pass
Add-SqlLogin -ServerInstance $configuration.databasesConfig.databaseServer -LoginName "edfi" -LoginType "SqlLogin" -DefaultDatabase "master" -GrantConnectSql -Enable -LoginPSCredential $Credential
$server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $configuration.databasesConfig.databaseServer
$serverRole = $server.Roles | Where-Object {$_.Name -eq 'sysadmin'}
$serverRole.AddMember("edfi")

#--- Start EdFi modules installation if required
if ($configuration.installDatabases){
    $db_parameters = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        databasesConfig = $configuration.databasesConfig
    }
    Install-EdFiDbs @db_parameters
}

if ($configuration.installWebApi){
    $api_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        webapiConfig = $configuration.webApiConfig
        databasesConfig = $configuration.databasesConfig
    }
    Install-EdFiAPI @api_parameters

    $installerPath = Install-AppCommonInstaller $toolsPath $downloadPath $AppCommonVersion

    # IIS-Components.psm1 must be imported after the IIS-WebServerManagementTools
    # windows feature has been enabled. This feature is enabled during Install-WebApi
    # by the AppCommon library.
    Import-Module "$installerPath\IIS\IIS-Components.psm1"

    $portNumber = IIS-Components\Get-PortNumber $configuration.webSiteName

    $expectedWebApiBaseUri = "https://$($env:computername):$($portNumber)/EdFiOdsWebApi"

    Set-ApiUrl $expectedWebApiBaseUri
}

if ($configuration.installSwaggerUI){
    Test-ApiUrl $configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl

    Test-ApiUrl $configuration.swaggerUIConfig.swaggerAppSettings.apiVersionUrl

    if((Test-YearSpecificMode $configuration.databasesConfig.apiMode)) {
        $configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl += "{0}/" -f (Get-Date).Year
    }

    $swagger_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        swaggerUIConfig = $configuration.swaggerUIConfig
    }
    Install-EdFiSwagger @swagger_parameters
}

if ($configuration.installAdminApp){
    $admin_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        adminAppConfig = $configuration.adminAppConfig
        databasesConfig = $configuration.databasesConfig
    }
    Install-EdFiAdmin @admin_parameters
}

if ($configuration.installAMT){

    Write-Host "Installing AMT..." -ForegroundColor Cyan

    $parameters = @{
        databasesConfig          = $configuration.databasesConfig
        amtDownloadPath          = $configuration.amtConfig.amtDownloadPath
        amtInstallerPath         = $configuration.amtConfig.amtInstallerPath
        amtOptions               = $configuration.amtConfig.options
        version                  = $configuration.amtConfig.version
    }

    Install-amt @parameters

    Write-Host "AMT has been installed" -ForegroundColor Cyan
}

if($configuration.installBulkLoadClient) {

    $parameters = @{
        urlDownloadODSSource            = $configuration.bulkLoadClientConfig.urlDownloadODSSource
        urlDownloadSamples              = $configuration.bulkLoadClientConfig.urlDownloadSamples
        urlDownloadSampleData           = $configuration.bulkLoadClientConfig.urlDownloadSampleData
        urlODSImp                       = $configuration.bulkLoadClientConfig.urlODSImp
    }

    Write-Host "Installing Bulk Load Client..." -ForegroundColor Cyan

    Install-BulkLoadClient @parameters
}
