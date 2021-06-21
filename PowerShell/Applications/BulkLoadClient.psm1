#Requires -Version 5
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
    Installs the BulkLoadClient.
.DESCRIPTION
    Installs the BulkLoadClient.
.EXAMPLE
    PS c:\> Install-BulkLoadClient
#>
function Install-BulkLoadClient(){
	[CmdletBinding()]
	param (
		[string]
        [Parameter(Mandatory=$true)]
        $urlDownloadODSSource,
        [string]
        [Parameter(Mandatory=$true)]
        $urlDownloadSamples,
        [string]
        [Parameter(Mandatory=$true)]
        $urlDownloadSampleData,
        [string]
        [Parameter(Mandatory=$true)]
        $urlODSImp
	)

    $hostName = [System.Net.Dns]::GetHostName()

    New-Item -ItemType Directory -Force -Path C:\Source\Ed-Fi-ODS

    New-Item -ItemType Directory -Force -Path C:\Source\Ed-Fi-SampleDataLoad

    New-Item -ItemType Directory -Force -Path C:\Source\Ed-Fi-ODS-Implementation

    Write-Host "Downloading Ed-Fi-ODS Source Code..." -ForegroundColor Cyan

	$pathToSave = "C:\Source\Ed-Fi_Tech_Suite.zip"

	$webClient = New-Object System.Net.WebClient

	$webClient.DownloadFile($urlDownloadODSSource, $pathToSave)

	Write-Host "Downloading Complete..." -ForegroundColor Cyan

    Write-Host "Unzip files..." -ForegroundColor Cyan

    Expand-Archive -Path $pathToSave -DestinationPath C:\Source -Force

    Write-Host "Unzip files Complete..." -ForegroundColor Cyan

    $sourceDirectory  = "C:\Source\Ed-Fi-ODS-5.1.0\*"

    $destinationDirectory = "C:\Source\Ed-Fi-ODS"

    Copy-item -Force -Recurse -Verbose $sourceDirectory -Destination $destinationDirectory

    Remove-Item C:\Source\Ed-Fi-ODS-5.1.0 -Recurse

    Write-Host "Downloading Samples XMLS..." -ForegroundColor Cyan

	$pathToSave = "C:\Source\Samples.zip"

	$webClient.DownloadFile($urlDownloadSamples, $pathToSave)

    Write-Host "Unzip Samples XMLS..." -ForegroundColor Cyan

	Expand-Archive -Path $pathToSave -DestinationPath C:\Source -Force

    Remove-Item C:\Source\Samples.zip -Recurse

    Write-Host "Downloading Samples Structure..." -ForegroundColor Cyan

    $pathToSave = "C:\Source\SampleData.zip"

	$webClient.DownloadFile($urlDownloadSampleData, $pathToSave)

    Write-Host "Unzip Samples Structure..." -ForegroundColor Cyan

	Expand-Archive -Path $pathToSave -DestinationPath C:\Source\Ed-Fi-SampleDataLoad -Force

    Remove-Item C:\Source\SampleData.zip -Recurse

    Remove-Item C:\Source\Ed-Fi_Tech_Suite.zip -Recurse

    Write-Host "Copying files..." -ForegroundColor Cyan

    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\*" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Sample XML"

    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Descriptors\*" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"

    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\Standards.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"
    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\EducationOrganization.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"
    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\CreditCategoryDescriptor.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"
    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\IndicatorDescriptor.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"
    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\IndicatorGroupDescriptor.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"
    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-Standard-3.2.0-c\Samples\Sample XML\IndicatorLevelDescriptor.xml" -Destination "C:\Source\Ed-Fi-SampleDataLoad\Bootstrap"

    Remove-Item C:\Source\Ed-Fi-Standard-3.2.0-c -Recurse

    ((Get-Content -path C:\Source\Ed-Fi-ODS\Utilities\DataLoading\EdFi.BulkLoadClient.Console\App.config -Raw) -replace '/metadata/data/v3/dependencies','/EdFiOdsWebApi/metadata/data/v3/dependencies') | Set-Content -Path C:\Source\Ed-Fi-ODS\Utilities\DataLoading\EdFi.BulkLoadClient.Console\App.config

    ((Get-Content -path C:\Source\Ed-Fi-ODS\Utilities\DataLoading\EdFi.BulkLoadClient.Console\App.config -Raw) -replace 'http://localhost:54746',"https://$hostName/EdFiOdsWebApi") | Set-Content -Path C:\Source\Ed-Fi-ODS\Utilities\DataLoading\EdFi.BulkLoadClient.Console\App.config

    ((Get-Content -path C:\Source\Ed-Fi-SampleDataLoad\LoadBootstrapData.ps1 -Raw) -replace 'http://localhost:54746',"https://$hostName/EdFiOdsWebApi") | Set-Content -Path C:\Source\Ed-Fi-SampleDataLoad\LoadBootstrapData.ps1

    ((Get-Content -path C:\Source\Ed-Fi-SampleDataLoad\LoadSampleData.ps1 -Raw) -replace 'http://localhost:54746',"https://$hostName/EdFiOdsWebApi") | Set-Content -Path C:\Source\Ed-Fi-SampleDataLoad\LoadSampleData.ps1

    Set-Location -Path "C:\Source\Ed-Fi-ODS\Utilities\DataLoading"

    $command = "dotnet build"

	Invoke-Expression -Command $command

    $webClient.DownloadFile($urlODSImp, "C:\Source\Ed-Fi-ODS-Implementation\ODSImp.zip")

	Expand-Archive -Path "C:\Source\Ed-Fi-ODS-Implementation\ODSImp.zip" -DestinationPath "C:\Source\Ed-Fi-ODS-Implementation" -Force

    Copy-item -Force -Recurse -Verbose "C:\Source\Ed-Fi-ODS-Implementation\Ed-Fi-ODS-Implementation-5.1.0\*" -Destination "C:\Source\Ed-Fi-ODS-Implementation"

    Remove-Item "C:\Source\Ed-Fi-ODS-Implementation\ODSImp.zip" -Recurse

    Remove-Item "C:\Source\Ed-Fi-ODS-Implementation\Ed-Fi-ODS-Implementation-5.1.0" -Recurse

    Write-Host "Finished..." -ForegroundColor Cyan
}

Export-ModuleMember Install-BulkLoadClient
