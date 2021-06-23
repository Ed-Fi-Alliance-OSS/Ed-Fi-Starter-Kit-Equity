#Requires -Version 5
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$adminAppVersion = '2.2.0'

$packageDetails = @{
    packageName = 'EdFi.Suite3.Installer.AdminApp'
    version = '2.2.0'
}

Import-Module "$PSScriptRoot\nuget-helper.psm1"

<#
.SYNOPSIS
    Installs the Ed-Fi Admin App.
.DESCRIPTION
    Installs the Ed-Fi Admin App.
.EXAMPLE
    PS c:\> Install-EdFiAdmin
#>

function New-AdminAppParameters {
    param (
        [Hashtable] $adminAppConfig,
        [Hashtable] $databasesConfig,
        [String] $toolsPath,
        [String] $downloadPath
    )

    $dbConnectionInfo = @{
        Server = $databasesConfig.databaseServer
        Port = $databasesConfig.databasePort
        UseIntegratedSecurity = $databasesConfig.applicationCredentials.useIntegratedSecurity
        Username = $databasesConfig.applicationCredentials.databaseUser
        Password = $databasesConfig.applicationCredentials.databasePassword
        Engine = $databasesConfig.engine
    }

    $adminAppFeatures = @{
        ApiMode = $databasesConfig.apiMode
    }

    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageVersion = $adminAppVersion
        WebApplicationPath = $adminAppConfig.installationDirectory
        OdsApiUrl = $adminAppConfig.odsApi.apiUrl
        InstallCredentialsUser = $databasesConfig.installCredentials.databaseUser
        InstallCredentialsPassword = $databasesConfig.installCredentials.databasePassword
        InstallCredentialsUseIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
        AdminDatabaseName = $databasesConfig.adminDatabaseName
        OdsDatabaseName = $databasesConfig.odsDatabaseName
        SecurityDatabaseName = $databasesConfig.securityDatabaseName
        AdminAppFeatures = $adminAppFeatures
        DbConnectionInfo = $dbConnectionInfo
    }
}
function Install-EdFiAdmin(){
	[CmdletBinding()]
	param (
		# IIS web site name
		[string]
		[Parameter(Mandatory=$true)]
		$webSiteName,
		# Path for storing installation tools
		[string]
		[Parameter(Mandatory=$true)]
		$toolsPath,
		# Path for storing downloaded packages
		[string]
		[Parameter(Mandatory=$true)]
		$downloadPath,
		# Hashtable containing Admin App settings and the installation directory
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$adminAppConfig,
		# Hashtable containing information about the databases and its server
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$databasesConfig
	)

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Admin App process starting..." -ForegroundColor Magenta

    $paths = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
    }

    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths

	Write-Host "Start installation..." -ForegroundColor Cyan

    $adminAppParams = @{
        adminAppConfig = $adminAppConfig
        databasesConfig = $databasesConfig
        toolsPath = $toolsPath
        downloadPath = $downloadPath
    }
    $parameters = New-AdminAppParameters @adminAppParams

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsAdminApp.psm1"
    Install-EdFiOdsAdminApp @parameters
}

Export-ModuleMember Install-EdFiAdmin
