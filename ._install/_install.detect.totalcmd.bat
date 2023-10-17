@echo off

setlocal

if defined DETECT_TOTALCMD_INSTALL_DIR_CHECK if %DETECT_TOTALCMD_INSTALL_DIR_CHECK%0 NEQ 0 exit /b 0

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_TOTALCMD_INSTALL_DIR="
set "DETECTED_TOTALCMD_INI_FILE_DIR="

echo.Searching Total Commander installation...

rem drop last error level
type nul >nul

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param IniFileName ^
  "HKCU\SOFTWARE\Ghisler\Total Commander" "HKCU\SOFTWARE\Wow6432Node\Ghisler\Total Commander" ^
  "HKLM\SOFTWARE\Ghisler\Total Commander" "HKLM\SOFTWARE\Wow6432Node\Ghisler\Total Commander"`) do (
  set "INSTALL_DIR=%%j"
  set "INI_FILE_NAME=%%k"
  call :FIND_INSTALL_DIR_AND_INI_PATH && goto INSTALL_DIR_AND_INI_PATH_END
)

goto INSTALL_DIR_AND_INI_PATH_END

:FIND_INSTALL_DIR_AND_INI_PATH
if not defined INSTALL_DIR exit /b 1
if not defined INI_FILE_NAME exit /b 1

set "INSTALL_DIR=%INSTALL_DIR:"=%"
set "INI_FILE_NAME=%INI_FILE_NAME:"=%"

if "%INSTALL_DIR%" == "." set "INSTALL_DIR="
if "%INI_FILE_NAME%" == "." set "INI_FILE_NAME="

if not defined INSTALL_DIR exit /b 1

set "INI_FILE_DIR="
if defined INI_FILE_NAME call :CANONICAL_PATH INI_FILE_DIR "%INI_FILE_NAME%\.."

if not exist "%INI_FILE_DIR%\*" set "INI_FILE_DIR="

if not exist "%INSTALL_DIR%\*" exit /b 1

if defined INSTALL_DIR call :CANONICAL_PATH DETECTED_TOTALCMD_INSTALL_DIR "%%INSTALL_DIR%%"
if defined INI_FILE_DIR call :CANONICAL_PATH DETECTED_TOTALCMD_INI_FILE_DIR "%%INI_FILE_DIR%%"

exit /b 0

:INSTALL_DIR_AND_INI_PATH_END
if defined DETECTED_TOTALCMD_INSTALL_DIR (
  echo. * TOTALCMD_INSTALL_DIR="%DETECTED_TOTALCMD_INSTALL_DIR%"
  if defined DETECTED_TOTALCMD_INI_FILE_DIR echo. * TOTALCMD_INI_FILE_DIR="%DETECTED_TOTALCMD_INI_FILE_DIR%"
) else (
  echo.%?~nx0%: warning: Total Commander installation directory is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TOTALCMD_INSTALL_DIR=%DETECTED_TOTALCMD_INSTALL_DIR%"
  set "DETECTED_TOTALCMD_INI_FILE_DIR=%DETECTED_TOTALCMD_INI_FILE_DIR%"
)

set DETECT_TOTALCMD_INSTALL_DIR_CHECK=1

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
