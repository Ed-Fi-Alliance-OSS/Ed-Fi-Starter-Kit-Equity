#Requires -Version 5
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Install-Choco {
    if (Get-Command "choco.exe" -ErrorAction SilentlyContinue){
        Write-Host "Chocolatey is already installed. Setting choco command."
    } else {
        Write-Host "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force;[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        $ChocoCmd = Get-Command "choco.exe" -ErrorAction SilentlyContinue
        $ChocolateyInstall = Convert-Path "$($ChocoCmd.Path)\..\.."
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        RefreshEnv.cmd
        Update-SessionEnvironment
    }
    return Get-Command "choco.exe" -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Configures a VM for Starter Kit Equity by installing all prerequisites.
.DESCRIPTION
    Downloads Chocolatey. Installs Dot Net Framework 4.8, SQL Server 2019 and SSMS and google chrome
.EXAMPLE
    Install-PreReq
    Downloads Chocolatey
    Installs prerequisites
.NOTES
    This will install the prerequisites for the ODS/API/Admin applications.
#>
function Create-Sql-Alias(){
    #Name of your SQL Server Alias
    $AliasName = "."

    #These are the two Registry locations for the SQL Alias 
    $x86 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
    $x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
    
    #if the ConnectTo key doesn't exists, create it.
    if ((test-path -path $x86) -ne $True)
    {
        New-Item $x86
    }
    
    if ((test-path -path $x64) -ne $True)
    {
        New-Item $x64
    }
    
    #Define SQL Alias 
    $NamedPipeAliasName = 'DBNMPNTW,\\.\PIPE\MSSQL$SQLEXPRESS\sql\query'
    
    #Create TCP/IP Aliases
    New-ItemProperty -Path $x86 -Name $AliasName -PropertyType String -Value $NamedPipeAliasName
    New-ItemProperty -Path $x64 -Name $AliasName -PropertyType String -Value $NamedPipeAliasName
}

function Enable-Mixed-Mode(){
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQLServer' -Name LoginMode -Value 2 -Force
}

function Enable-IisFeature {
    Param (
        [string] [Parameter(Mandatory=$true)] $featureName
    )

    $feature = Get-WindowsOptionalFeature -FeatureName $featureName -Online
    if (-not $feature -or $feature.State -ne "Enabled") {
        Write-Debug "Enabling Windows feature: $($featureName)"

        $result = Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart
        return $result.RestartNeeded
    }
    return $false
}

function Enable-RequiredIisFeatures {
    Write-Host "Installing IIS Features in Windows that are needed before .NET Core Hosting bundle can be installed" -ForegroundColor Cyan

    Enable-IisFeature IIS-WebServerRole
    Enable-IisFeature IIS-WebServer
    Enable-IisFeature IIS-CommonHttpFeatures
    Enable-IisFeature IIS-HttpErrors
    Enable-IisFeature IIS-HttpRedirect
    Enable-IisFeature IIS-ApplicationDevelopment
    Enable-IisFeature IIS-HealthAndDiagnostics
    Enable-IisFeature IIS-HttpLogging
    Enable-IisFeature IIS-LoggingLibraries
    Enable-IisFeature IIS-RequestMonitor
    Enable-IisFeature IIS-HttpTracing
    Enable-IisFeature IIS-Security
    Enable-IisFeature IIS-RequestFiltering
    Enable-IisFeature IIS-Performance
    Enable-IisFeature IIS-WebServerManagementTools
    Enable-IisFeature IIS-IIS6ManagementCompatibility
    Enable-IisFeature IIS-Metabase
    Enable-IisFeature IIS-ManagementConsole
    Enable-IisFeature IIS-BasicAuthentication
    Enable-IisFeature IIS-WindowsAuthentication
    Enable-IisFeature IIS-StaticContent
    Enable-IisFeature IIS-DefaultDocument
    Enable-IisFeature IIS-WebSockets
    Enable-IisFeature IIS-ApplicationInit
    Enable-IisFeature IIS-ISAPIExtensions
    Enable-IisFeature IIS-ISAPIFilter
    Enable-IisFeature IIS-HttpCompressionStatic
    Enable-IisFeature NetFx4Extended-ASPNET45
    Enable-IisFeature IIS-NetFxExtensibility45
    Enable-IisFeature IIS-ASPNET45
}

function Install-PreRequisites(){
    $prerequisites = @(
        "dotnetfx",
        "dotnetcore-sdk",
        "dotnetcore-3.1-windowshosting",
        "sql-server-2019  --params=`"'/IgnorePendingReboot'`"",
        "sql-server-management-studio",
        "googlechrome")

    Start-Transcript -Path ".\starter-kit-setup.log"

    Install-Choco
    choco feature disable --name showDownloadProgress --execution-timeout=$installTimeout
    Enable-RequiredIisFeatures
    choco install dotnetfx -y --ignore-pending-reboot --execution-timeout=$installTimeout
    choco install dotnetcore-sdk -y --ignore-pending-reboot --execution-timeout=$installTimeout
    choco install dotnetcore-3.1-windowshosting -y --ignore-pending-reboot --execution-timeout=$installTimeout
    choco install sql-server-express -y --params=`"'/IgnorePendingReboot'`" --execution-timeout=$installTimeout
    
    Create-Sql-Alias
    Enable-Mixed-Mode

    choco install sql-server-management-studio -y --ignore-pending-reboot --execution-timeout=$installTimeout
    choco install GoogleChrome -y --ignore-pending-reboot --ignore-checksums --execution-timeout=$installTimeout
    choco install powerbi -y --ignore-pending-reboot --ignore-checksums --execution-timeout=$installTimeout

    Stop-Transcript
}

Install-PreRequisites
