#Requires -Version 5
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$AppCommonVersion = "1.0.3"
$root = $PSScriptRoot

Import-Module -Force "$PSScriptRoot\nuget-helper.psm1"
Import-Module "$PSScriptRoot\multi-instance-helper.psm1"

<#
.SYNOPSIS
    Installs the Ed-Fi Databases.
.DESCRIPTION
    Installs the Ed-Fi Databases.
.EXAMPLE
    PS c:\> Install-EdFiDbs
#>

function SetValue($object, $key, $Value)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { SetValue -object $object.$p1 -key $p2 -Value $Value }
    else { return $object.$p1 = $Value }
}

function Install-AppCommon {
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

    $env:PathResolverRepositoryOverride = "Ed-Fi-Ods;Ed-Fi-ODS-Implementation"
    Import-Module -Force -Scope Global "$installerPath/Ed-Fi-ODS-Implementation/logistics/scripts/modules/path-resolver.psm1"
    Import-Module -Force $folders.modules.invoke("packaging/nuget-helper.psm1")
    Import-Module -Force $folders.modules.invoke("tasks/TaskHelper.psm1")
    Import-Module -Force $folders.modules.invoke("tools/ToolsHelper.psm1")

    # Import the following with global scope so that they are available inside of script blocks
    Import-Module -Force "$installerPath/Application/Install.psm1" -Scope Global
    Import-Module -Force "$installerPath/Application/Configuration.psm1" -Scope Global
}
function Install-EdFiDbs() {
    [CmdletBinding()]
    param (
        [string]
        [Parameter(Mandatory = $true)]
        [string] $toolsPath,
        [string]
        [Parameter(Mandatory = $true)]
        [string] $downloadPath,
        [Hashtable]
        [Parameter(Mandatory = $true)]
        [Hashtable] $databasesConfig
    )

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Databases module process starting..." -ForegroundColor Magenta

    Write-Host "Installing App Common"
    Install-AppCommon $toolsPath $downloadPath $AppCommonVersion

    $engine = $databasesConfig.engine
    if ($engine -ieq "Postgres") {
        $engine = "PostgreSQL"
    }

    $databasePort = $databasesConfig.databasePort
    $databaseUser = $databasesConfig.installCredentials.databaseUser
    $databasePassword = $databasesConfig.installCredentials.databasePassword
    $useIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
    $odsTemplate = $databasesConfig.odsTemplate
    $dropDatabases = $databasesConfig.dropDatabases
    $noDuration = $databasesConfig.noDuration

    $packageDetails = @{
        packageName  = 'EdFi.Suite3.RestApi.Databases'
        version      = $databasesConfig.databasePackageVersion
        toolsPath    = $toolsPath
        downloadPath = $downloadPath
    }

    $EdFiRepositoryPath = Install-EdFiPackage @packageDetails
    $env:PathResolverRepositoryOverride = $pathResolverRepositoryOverride = "Ed-Fi-ODS;Ed-Fi-ODS-Implementation"

    $implementationRepo = $pathResolverRepositoryOverride.Split(';')[1]
    Import-Module -Force -Scope Global "$EdFiRepositoryPath\$implementationRepo\logistics\scripts\modules\path-resolver.psm1"

    Import-Module -Force -Scope Global (Join-Path $EdFiRepositoryPath "Deployment.psm1")
    Import-Module -Force -Scope Global $folders.modules.invoke("tasks\TaskHelper.psm1")

    # Validate arguments
    if (@("SQLServer", "PostgreSQL") -notcontains $engine) {
        write-ErrorAndThenExit "Please configure valid engine name. Valid Input: PostgreSQL or SQLServer."
    }
    if ($engine -eq "SQLServer") {
        if (-not $databasePassword) { $databasePassword = $env:SqlServerPassword }
        if (-not $databasePort) { $databasePort = 1433 }
        if ($useIntegratedSecurity -and ($databaseUser -or $databasePassword)) {
            Write-Info "Will use integrated security even though username and/or password was provided."
        }
        if (-not $useIntegratedSecurity) {
            if (-not $databaseUser -or (-not $databasePassword)) {
                write-ErrorAndThenExit "When not using integrated security, must provide both username and password for SQL Server."
            }
        }
    }
    else {
        if (-not $databasePort) { $databasePort = 5432 }
        if ($databasePassword) { $env:PGPASSWORD = $databasePassword }
    }

    $dbConnectionInfo = @{
        Server                = $databasesConfig.databaseServer
        Port                  = $databasesConfig.databasePort
        UseIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
        Username              = $databasesConfig.installCredentials.databaseUser
        Password              = $databasesConfig.installCredentials.databasePassword
        Engine                = $databasesConfig.engine
    }

    $adminDbConnectionInfo = $dbConnectionInfo.Clone()
    $adminDbConnectionInfo.DatabaseName = $databasesConfig.adminDatabaseName

    $odsDbConnectionInfo = $dbConnectionInfo.Clone()
    $odsDbConnectionInfo.DatabaseName = $databasesConfig.odsDatabaseName

    $securityDbConnectionInfo = $dbConnectionInfo.Clone()
    $securityDbConnectionInfo.DatabaseName = $databasesConfig.securityDatabaseName

    $configFile = "$root\PostgresqlDataServer.config"

    if ($engine -ieq "SQLServer") {
        $configFile = "$root\SqlDataServer.config"
    }

    Write-Host "Starting installation..." -ForegroundColor Cyan

    #Changing config file
    $json = Get-Content (Join-Path $EdFiRepositoryPath "configuration.json") | ConvertFrom-Json

    SetValue -object $json -key "ConnectionStrings.EdFi_Ods" -value "server= .\SQLEXPRESS;trusted_connection=True;database=EdFi_{0};Application Name=EdFi.Ods.WebApi"
    SetValue -object $json -key "ConnectionStrings.EdFi_Security" -value "server= .\SQLEXPRESS;trusted_connection=True;database=EdFi_Security;persist security info=True;Application Name=EdFi.Ods.WebApi"
    SetValue -object $json -key "ConnectionStrings.EdFi_Admin" -value "server= .\SQLEXPRESS;trusted_connection=True;database=EdFi_Admin;Application Name=EdFi.Ods.WebApi"
    SetValue -object $json -key "ConnectionStrings.EdFi_Master" -value "server= .\SQLEXPRESS;trusted_connection=True;database=master;Application Name=EdFi.Ods.WebApi"

    SetValue -object $json -key "ApiSettings.Mode" -value "SharedInstance"
    SetValue -object $json -key "ApiSettings.Engine" -value "SQLServer"
    SetValue -object $json -key "ApiSettings.MinimalTemplateScript" -value "EdFiMinimalTemplate"
    SetValue -object $json -key "ApiSettings.PopulatedTemplateScript" -value "GrandBend"
    SetValue -object $json -key "ApiSettings.OdsDatabaseTemplateName" -value "populated"

    $json | ConvertTo-Json | Out-File (Join-Path $EdFiRepositoryPath "configuration.json")

    Initialize-DeploymentEnvironment
}

Export-ModuleMember Install-EdFiDbs

