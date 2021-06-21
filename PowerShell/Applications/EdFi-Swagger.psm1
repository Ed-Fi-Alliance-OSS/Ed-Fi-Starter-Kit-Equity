#Requires -Version 5
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$swaggerUIVersion = "5.2.14406"

Import-Module "$PSScriptRoot\nuget-helper.psm1"

<#
.SYNOPSIS
    Installs the Ed-Fi Swagger.
.DESCRIPTION
    Installs the Ed-Fi Swagger.
.EXAMPLE
    PS c:\> Install-EdFiSwagger
#>
function Install-EdFiSwagger(){
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

        # Hashtable containing SwaggerUI settings and the installation directory
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $swaggerUIConfig
    )

    $paths = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
    }

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Swagger module process starting..." -ForegroundColor Magenta

    $packageDetails = @{
        packageName = 'EdFi.Suite3.Installer.SwaggerUI'
        version = '5.2.42'
    }

    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths

    $parameters = New-SwaggerUIParameters $swaggerUIConfig $toolsPath $downloadPath

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsSwaggerUI.psm1"

    Write-Host "Starting installation..." -ForegroundColor Cyan
    Install-EdFiOdsSwaggerUI @parameters
}

function New-SwaggerUIParameters {
    param (
        [Hashtable] $swaggerUIConfig,
        [String] $toolsPath,
        [String] $downloadPath
    )

    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageVersion = $swaggerUIVersion
        WebApplicationPath = $swaggerUIConfig.installationDirectory
        WebApiMetadataUrl = $swaggerUIConfig.swaggerAppSettings.apiMetadataUrl
        WebApiVersionUrl = $swaggerUIConfig.swaggerAppSettings.apiVersionUrl
        DisablePrepopulatedCredentials = $True
    }
}

Export-ModuleMember Install-EdFiSwagger

