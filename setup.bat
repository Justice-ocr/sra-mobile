@echo off
chcp 65001 >nul
echo ========================================
echo   SRA Mobile 环境安装脚本
echo ========================================
echo.

:: 检查Flutter是否已安装
where flutter >nul 2>&1
if %errorlevel%==0 (
    echo [✓] 检测到 Flutter 已安装
    flutter --version
    goto :setup_project
)

echo [1/3] 下载 Flutter SDK（中国镜像，约700MB）...
echo 请稍候，这可能需要5-15分钟...
echo.

powershell -Command "Invoke-WebRequest -Uri 'https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip' -OutFile '%TEMP%\flutter_sdk.zip' -UseBasicParsing"

if not exist "%TEMP%\flutter_sdk.zip" (
    echo [错误] 下载失败，请手动下载：
    echo https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [2/3] 解压 Flutter SDK...
powershell -Command "Expand-Archive -Path '%TEMP%\flutter_sdk.zip' -DestinationPath 'C:\src' -Force"

echo [3/3] 配置 PATH...
setx PATH "%PATH%;C:\src\flutter\bin" /M
set PATH=%PATH%;C:\src\flutter\bin

echo [✓] Flutter SDK 安装完成！
echo.

:setup_project
echo [4/5] 安装项目依赖...
cd /d "%~dp0"

:: 确保Flutter项目结构存在
if not exist "android" (
    echo 初始化 Flutter 项目结构...
    flutter create --org com.sra . --overwrite
    :: 恢复我们的代码文件
    xcopy /Y lib_backup\* lib\ /E >nul 2>&1
)

flutter pub get

echo [5/5] 检查环境...
flutter doctor

echo.
echo ========================================
echo   安装完成！
echo ========================================
echo.
echo 下一步：
echo   1. 连接 Android 手机（开启 USB 调试）
echo      或启动 Android 模拟器
echo   2. 运行：flutter run
echo   3. 在登录界面输入 SRA 服务器地址和 Token
echo.
echo 提示：
echo   - SRA 服务器需要开启"远程连接"功能
echo   - 默认 Token: starrailassistant
echo   - 默认地址: http://192.168.x.x:5074
echo.
pause
