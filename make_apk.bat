@echo off
set B=D:\QGC-4.1.1\build\Qt_5_15_2_for_Android_Multi_Abi_Debug
set J=%B%\android-QGroundControl-deployment-settings.json

echo [1/5] Removing android-36 platform
if exist E:\Android\Sdk\platforms\android-36 rmdir /s /q E:\Android\Sdk\platforms\android-36

echo [2/5] Setting build-tools to 30.0.3
powershell -NoProfile -Command "$j='%J%'; $t=[IO.File]::ReadAllText($j); $t=$t.Replace('\"sdkBuildToolsRevision\": \"36.1.0\"','\"sdkBuildToolsRevision\": \"30.0.3\"'); [IO.File]::WriteAllText($j,$t,(New-Object Text.UTF8Encoding($false)))"
findstr /i "sdkBuildToolsRevision" "%J%"

echo [3/5] Copying gradle file and d2xx.jar
copy /Y D:\QGC-4.1.1\android\build.gradle "%B%\android-build\build.gradle"
copy /Y D:\QGC-4.1.1\android\libs\d2xx.jar "%B%\android-build\libs\"

echo [4/5] Clearing stale gradle state
if exist "%B%\android-build\build" rmdir /s /q "%B%\android-build\build"
if exist "%B%\android-build\.gradle" rmdir /s /q "%B%\android-build\.gradle"

echo [5/5] Packaging APK
D:\gcs_tech\5.15.2\android\bin\androiddeployqt.exe --input "%J%" --output "%B%\android-build" --android-platform android-30 --jdk "C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot" --gradle
if errorlevel 1 (echo BUILD FAILED & exit /b 1)

echo Installing
E:\Android\Sdk\platform-tools\adb install -r "%B%\android-build\build\outputs\apk\debug\android-build-debug.apk"
echo Done.