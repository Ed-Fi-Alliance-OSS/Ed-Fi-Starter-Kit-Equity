function Install-EdFiPackage {
    param (
        $packageName,
        $version,
        $toolsPath = "C:\temp\tools",
        $downloadPath = "C:\temp\downloads"
    )

    $packageSource = 'https://www.myget.org/F/ed-fi/'

    $downloadedPackagePath = Join-Path $downloadPath "$packageName.$version"

    &"$toolsPath\nuget" install $packageName -source $packageSource -Version $version -outputDirectory $downloadPath -ConfigFile "$PSScriptRoot\nuget.config" | Out-Host

    if ($LASTEXITCODE) {
        throw "Failed to install package $packageName $version"
    }

    return Resolve-Path $downloadedPackagePath
}
