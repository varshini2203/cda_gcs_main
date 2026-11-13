@echo off
set QTDIR=D:\gcs_tech\5.15.2\android
set ANDROID_SDK_ROOT=E:\Android\Sdk
set ANDROID_NDK_ROOT=E:\Android\Sdk\ndk\21.3.6528147
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot
set PATH=%QTDIR%\bin;%ANDROID_NDK_ROOT%\prebuilt\windows-x86_64\bin;%JAVA_HOME%\bin;C:\Users\sriva\AppData\Local\Android\Sdk\platform-tools;%PATH%

cd /d D:\QGC-4.1.1
rmdir /s /q build\cli
mkdir build\cli
cd build\cli

qmake ..\..\qgroundcontrol.pro -spec android-clang CONFIG+=release "ANDROID_ABIS=arm64-v8a"
if errorlevel 1 goto fail
make -j8
if errorlevel 1 goto fail
make apk_install_target
if errorlevel 1 goto fail
androiddeployqt --input android-qgroundcontrol-deployment-settings.json --output android-build --android-platform android-30 --gradle --debug
if errorlevel 1 goto fail

adb uninstall org.mavlink.qgroundcontrol
adb install android-build\build\outputs\apk\debug\android-build-debug.apk
if errorlevel 1 goto fail
adb shell monkey -p org.mavlink.qgroundcontrol 1
echo BUILD OK
goto end

:fail
echo BUILD FAILED - copy the error above
:end
pause