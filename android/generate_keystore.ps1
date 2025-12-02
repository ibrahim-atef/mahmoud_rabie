# Find Java keytool from common Android Studio locations
$possiblePaths = @(
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\keytool.bat"
)

$keytoolPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $keytoolPath = $path
        Write-Host "Found keytool at: $path"
        break
    }
}

if (-not $keytoolPath) {
    Write-Host "ERROR: Could not find keytool. Please ensure Android Studio or Java JDK is installed."
    Write-Host "Searching for keytool in Program Files..."
    $found = Get-ChildItem "C:\Program Files" -Recurse -Filter "keytool.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytoolPath = $found.FullName
        Write-Host "Found keytool at: $keytoolPath"
    } else {
        Write-Host "Please install Java JDK and run this script again, or run the following command manually:"
        Write-Host 'keytool -genkey -v -keystore spring-series-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias spring-series-key -storepass spring123 -keypass spring123 -dname "CN=Spring Series, OU=Development, O=Spring Series, L=City, S=State, C=US"'
        exit 1
    }
}

Write-Host "Generating keystore..."
& $keytoolPath -genkey -v -keystore "spring-series-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias "spring-series-key" -storepass "spring123" -keypass "spring123" -dname "CN=Spring Series, OU=Development, O=Spring Series, L=City, S=State, C=US"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Keystore generated successfully at: spring-series-release-key.jks"
    Write-Host "Store Password: spring123"
    Write-Host "Key Password: spring123"
    Write-Host "Key Alias: spring-series-key"
} else {
    Write-Host "Failed to generate keystore. Error code: $LASTEXITCODE"
}
