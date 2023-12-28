@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_TOTALCMD_PRODUCT_VERSION="
set "DETECTED_TOTALCMD_INSTALL_DIR="
set "DETECTED_TOTALCMD_INI_FILE_DIR="

echo.Searching Total Commander installation...

call :DETECT %%*

echo. * TOTALCMD_PRODUCT_VERSION="%DETECTED_TOTALCMD_PRODUCT_VERSION%"
echo. * TOTALCMD_MIN_VERSION="%TOTALCMD_MIN_VER_STR%"
echo. * TOTALCMD_INSTALL_DIR="%DETECTED_TOTALCMD_INSTALL_DIR%"
echo. * TOTALCMD_INI_FILE_DIR="%DETECTED_TOTALCMD_INI_FILE_DIR%"

if not defined DETECTED_TOTALCMD_INSTALL_DIR (
  echo.%?~nx0%: warning: Total Commander installation directory is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TOTALCMD_PRODUCT_VERSION=%DETECTED_TOTALCMD_PRODUCT_VERSION%"
  set "DETECTED_TOTALCMD_INSTALL_DIR=%DETECTED_TOTALCMD_INSTALL_DIR%"
  set "DETECTED_TOTALCMD_INI_FILE_DIR=%DETECTED_TOTALCMD_INI_FILE_DIR%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="
set "INI_FILE_NAME="

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param IniFileName ^
  "HKCU\SOFTWARE\Ghisler\Total Commander" "HKCU\SOFTWARE\Wow6432Node\Ghisler\Total Commander" ^
  "HKLM\SOFTWARE\Ghisler\Total Commander" "HKLM\SOFTWARE\Wow6432Node\Ghisler\Total Commander"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
  if not defined INI_FILE_NAME if not "%%k" == "." set "INI_FILE_NAME=%%k"
)

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" (
  call :CANONICAL_PATH DETECTED_TOTALCMD_INSTALL_DIR "%%INSTALL_DIR%%"
)

if defined INI_FILE_NAME call "%%CONTOOLS_ROOT%%/std/if_.bat" exist "%INI_FILE_NAME%" && (
  call :CANONICAL_PATH DETECTED_TOTALCMD_INI_FILE_DIR "%INI_FILE_NAME%\.."
)

set "RETURN_VALUE="
if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd64.exe" (
  call "%%CONTOOLS_ROOT%%/filesys/read_path_props" -v -x -lr ProductVersion "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd64.exe"
) else if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd.exe" (
  call "%%CONTOOLS_ROOT%%/filesys/read_path_props" -v -x -lr ProductVersion "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd.exe"
)

if defined RETURN_VALUE (
  setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!RETURN_VALUE!") do endlocal & set "DETECTED_TOTALCMD_PRODUCT_VERSION=%%i"
)

exit /b 0

:INSTALL_DIR_AND_INI_PATH_END

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
