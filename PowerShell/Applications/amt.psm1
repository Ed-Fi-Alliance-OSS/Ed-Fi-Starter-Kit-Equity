#Requires -version 5

$packageDetails = @{
    packageName = 'EdFi.AnalyticsMiddleTier'
}

$destinationName="{0}-{1}"
$amtUninstallArgumentList = "-c `"{0}`" -e {1} -u"
$amtInstallArgumentList = "-c `"{0}`" -o {1} -e {2}"
$amtConsoleApp = "EdFi.AnalyticsMiddleTier.Console.exe"
$packageUrl = 'https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier/releases/download/{1}/{0}-{1}.zip'
function Request-amt-Files{
    param (
        $packageName,
        $version,
        $amtPath = "C:\temp\",
        $downloadPath = "C:\temp\downloads\"
    )
	$Url = $packageUrl -f $packageName, $version
	
	if( -Not (Test-Path -Path $amtPath ) )
	{
        # Create the installer directory if it does not exist.
		New-Item -ItemType directory -Path $amtPath
	}
	if( -Not (Test-Path -Path $downloadPath ) )
	{
        # Create the download directory if it does not exist.
		New-Item -ItemType directory -Path $downloadPath
	}
		
	$ZipFile = Join-Path $downloadPath (($destinationName+".zip") -f $packageName, $version)
	
	Invoke-WebRequest -Uri $Url -OutFile $ZipFile 
	
    if ($LASTEXITCODE) {
        throw "Failed to download package $packageName $version"
    }

    return Resolve-Path $amtPath
}
function Expand-amt-Files {
    param (
        $packageName,
        $version,
        $amtPath = "C:\temp\",
        $downloadPath = "C:\temp\downloads\"
    )
    
    $amtVersionDestination = (Join-Path $amtPath $destinationName) -f $packageName,$version

    $ZipFile = Join-Path $downloadPath (($destinationName+".zip") -f $packageName, $version)
    
    Expand-Archive -Path $ZipFile -DestinationPath $amtVersionDestination -Force
    
    if ($LASTEXITCODE) {
        throw "Failed to extract package $packageName $version"
    }
}

function New-amt-ConnectionString{
    param (
        $databaseInfo
    )
    $postgresqlConnectionString="host={0};Database={1};user id={2};Password={3};port={4}" 
    $mssqlConnectionStringIntegrated="Server={0};Database={1};Integrated Security=SSPI;"
    $mssqlConnectionString="Server={0};Database={1};user id={2};Password={3};"
    if($databaseInfo.engine -ieq "SQLServer"){
        if($databaseInfo.UseIntegratedSecurity){
            return $mssqlConnectionStringIntegrated -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName
        }
        else{
            return $mssqlConnectionString -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName, $databaseInfo.applicationCredentials.databaseUser,$databaseInfo.applicationCredentials.databasePassword
        }
    }
    else{
        return $postgresqlConnectionString -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName, $databaseInfo.applicationCredentials.databaseUser,$databaseInfo.applicationCredentials.databasePassword,$databaseInfo.applicationCredentials.databasePort
    }
}
function Install-AMT {
    <#
    .SYNOPSIS
        Installs the Ed-Fi Analytics-Middle-Tier.

    .DESCRIPTION
        Installs the Ed-Fi Analytics-Middle-Tier using the configuration
        values provided.

    .EXAMPLE
        Installs the Analytics-Middle-Tier

        PS c:\> $amtInstallerPath = "C:/temp/tools/amt"
        PS c:\> $amtDownloadPath = "C:/temp/downloads/amt"
        PS c:\> $databasesConfig = @{}
        PS c:\> $amtOptions = "indexes rls qews ews chrab asmt"
    #>
    [CmdletBinding()]
    param (
        # Path for storing installation tools
        [string]
        [Parameter(Mandatory=$true)]
        $amtInstallerPath,

        # Path for storing downloaded packages
        [string]
        [Parameter(Mandatory=$true)]
        $amtDownloadPath,

        # Hashtable containing information about the databases and its server
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $databasesConfig,

        [string]
        [Parameter(Mandatory=$true)]
        $amtOptions,

        [string]
        [Parameter(Mandatory=$true)]
        $version
    )
  
    $paths = @{
        amtPath = $amtInstallerPath
        downloadPath = $amtDownloadPath
    }
    try {
        $databaseEngine = if($databasesConfig.engine -ieq "SQLServer"){"mssql"}else{"postgres"}

        Request-amt-Files @packageDetails $version @paths

        Expand-amt-Files @packageDetails $version @paths

        $connectionString = New-amt-ConnectionString $databasesConfig
    
        $consoleInstaller = Join-Path ((Join-Path $amtInstallerPath $destinationName) -f $packageDetails.packageName,$version) $amtConsoleApp
        
        Start-Process -NoNewWindow -FilePath $consoleInstaller -ArgumentList ($amtInstallArgumentList -f $connectionString, $amtOptions, $databaseEngine)
    }
    catch {
        Write-Host $_
        throw $_
    }
}

function Uninstall-AMT {
    <#
    .SYNOPSIS
        Uninstalls the Ed-Fi Analytics Middle Tier Views.

    .DESCRIPTION
        Uninstalls the Ed-Fi Analytics Middle Tier Views using the configuration
        values provided.

    .EXAMPLE
        Uninstalls the Ed-Fi Analytics Middle Tier Views

        PS c:\> $amtInstallerPath = "C:/temp/tools/amt"
        PS c:\> $amtDownloadPath = "C:/temp/downloads/amt"
        PS c:\> $databasesConfig = @{}
        PS c:\> $amtOptions = "indexes rls qews ews chrab asmt"
    #>
    [CmdletBinding()]
    param (
        # Path for storing installation tools
        [string]
        [Parameter(Mandatory=$true)]
        $amtInstallerPath,

        # Path for storing downloaded packages
        [string]
        [Parameter(Mandatory=$true)]
        $amtDownloadPath,

        # Hashtable containing information about the databases and its server
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $databasesConfig,

        [string]
        [Parameter(Mandatory=$true)]
        $amtOptions,

        [string]
        [Parameter(Mandatory=$true)]
        $version

    )
  
    $paths = @{
        amtPath = $amtInstallerPath
        downloadPath = $amtDownloadPath
    }
    try{
        $databaseEngine = if($databasesConfig.engine -ieq "SQLServer"){"mssql"}else{"postgres"}
        
        Request-amt-Files @packageDetails $version @paths

        Expand-amt-Files @packageDetails $version @paths

        $connectionString = New-amt-ConnectionString $databasesConfig
    
        $consoleInstaller = Join-Path ((Join-Path $amtInstallerPath $destinationName) -f $packageDetails.packageName,$version) $amtConsoleApp
        
        Start-Process -NoNewWindow -Wait -FilePath $consoleInstaller -ArgumentList ($amtUninstallArgumentList -f $connectionString, $databaseEngine)
    }
    catch {
        Write-Host $_
        throw $_
    }    
}

Export-ModuleMember Install-AMT, Uninstall-AMT
