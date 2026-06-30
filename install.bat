@echo off
chcp 65001 >nul
echo ========================================
echo   解压 Flutter SDK 并初始化项目
echo ========================================

if not exist "C:\src\flutter_sdk.zip" (
    echo [错误] C:\src\flutter_sdk.zip 不存在，请等待下载完成
    pause
    exit /b 1
)

echo [1/4] 解压 Flutter SDK...
powershell -Command "Expand-Archive -Path 'C:\src\flutter_sdk.zip' -DestinationPath 'C:\src' -Force"
echo [✓] 解压完成

echo [2/4] 添加到当前会话 PATH...
set PATH=%PATH%;C:\src\flutter\bin

echo [3/4] 安装项目依赖...
cd /d "%~dp0"
flutter pub get

echo [4/4] 环境检查...
flutter doctor

echo.
echo ========================================
echo   准备完成！
echo ========================================
echo.
echo 运行方式：
echo   连接 Android 手机后执行：flutter run
echo   或者在 Android Studio 中打开此目录
echo.
echo 注意：如果 flutter 命令不可用，请重新打开命令行
echo 或手动将 C:\src\flutter\bin 添加到系统 PATH
echo.
pause
