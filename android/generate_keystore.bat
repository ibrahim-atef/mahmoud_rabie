@echo off
echo Generating keystore for Spring Series...
"%JAVA_HOME%\bin\keytool" -genkey -v -keystore spring-series-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias spring-series-key -storepass spring123 -keypass spring123 -dname "CN=Spring Series, OU=Development, O=Spring Series, L=City, S=State, C=US"
if %ERRORLEVEL% EQU 0 (
    echo Keystore generated successfully!
) else (
    echo Failed to generate keystore. Please make sure JAVA_HOME is set.
)
pause
