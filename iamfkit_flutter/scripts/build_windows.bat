@echo off
REM build_windows.bat — builds iamf.dll for Windows x64
REM Usage: scripts\build_windows.bat
REM Requires: CMake, Visual Studio 2019+ or Build Tools, Ninja (optional)

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set REPO_ROOT=%SCRIPT_DIR%..

REM Allow CI to pass LIBIAMF_SRC explicitly; fall back to ..\code for local monorepo use
if "%LIBIAMF_SRC%"=="" (
  set LIBIAMF_SRC=%REPO_ROOT%\..\code
)

if not exist "%LIBIAMF_SRC%" (
  echo ERROR: libiamf source not found at %LIBIAMF_SRC%
  echo Set LIBIAMF_SRC=\path\to\libiamf\code or run from inside the monorepo.
  exit /b 1
)
echo =^> Using libiamf source: %LIBIAMF_SRC%

REM Normalize slashes for Windows compatibility
set LIBIAMF_SRC=%LIBIAMF_SRC:/=\%
set OUT_DIR=%REPO_ROOT%\windows
set BUILD_DIR=%LIBIAMF_SRC%\build_windows

echo =^> Building libiamf for Windows x64

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

where ninja >nul 2>nul
if %ERRORLEVEL% equ 0 (
  echo Ninja found! Using Ninja generator.
  set GENERATOR=-G Ninja
) else (
  echo Ninja not found. Using Visual Studio 17 2022.
  set GENERATOR=-G "Visual Studio 17 2022" -A x64
)

cmake -S "%LIBIAMF_SRC%" -B "%BUILD_DIR%" ^
  %GENERATOR% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DIAMF_BUILD_SHARED_LIB=ON ^
  -DENABLE_BUILD_CODECS=ON ^
  -DIAMF_ENABLE_BINAURALIZER=ON ^
  -DIAMF_TEST_TOOL=OFF ^
  -DBUILD_TESTING=OFF ^
  -DEIGEN_BUILD_TESTING=OFF

if %ERRORLEVEL% neq 0 (
  echo ERROR: CMake configure failed
  exit /b %ERRORLEVEL%
)

cmake --build "%BUILD_DIR%" --config Release

if %ERRORLEVEL% neq 0 (
  echo ERROR: CMake build failed
  exit /b %ERRORLEVEL%
)

if exist "%BUILD_DIR%\Release\iamf.dll" (
  copy "%BUILD_DIR%\Release\iamf.dll" "%OUT_DIR%\iamf.dll"
  copy "%BUILD_DIR%\Release\iamf.lib" "%OUT_DIR%\iamf.lib"
) else (
  copy "%BUILD_DIR%\iamf.dll" "%OUT_DIR%\iamf.dll"
  copy "%BUILD_DIR%\iamf.lib" "%OUT_DIR%\iamf.lib"
)
echo Done: Windows DLL at %OUT_DIR%\iamf.dll
