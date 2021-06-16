function Test-ApiUrl {
    param (
        [String] $apiUrl
    )
    if ([String]::IsNullOrEmpty($apiUrl)) {
        Write-Error "No API Url configured. Edit configuration.json and run install again."
        Exit -1
    }
}