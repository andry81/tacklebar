@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" INSTALL_TO_DIR PROJECT_LOG_FILE_NAME_DATE_TIME TACKLEBAR_PROJECT_EXTERNALS_ROOT || exit /b

if "%DETECTED_TOTALCMD_PRODUCT_VERSION%" == "" (
  echo.%?~%: error: `Total Commander` installation is not detected.
  echo.
  exit /b 255
) >&2

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" DETECTED_TOTALCMD_WINCMD_CONFIG_FILE || exit /b

echo.Searching for `Total Commander` buttonbar file...
echo.

set "TOTALCMD_BUTTONBAR_FILE_PATH="
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/get_inifile_key.vbs" "%DETECTED_TOTALCMD_WINCMD_CONFIG_FILE%" "Buttonbar" "Buttonbar"`) do set "TOTALCMD_BUTTONBAR_FILE_PATH=%%i"

if defined TOTALCMD_BUTTONBAR_FILE_PATH if exist "%TOTALCMD_BUTTONBAR_FILE_PATH%" goto INSTALL_TOTALCMD_BUTTONBAR_FILE

rem search in the Total Commander installation directory
if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR" ( set "TOTALCMD_BUTTONBAR_FILE_PATH=%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR" & goto INSTALL_TOTALCMD_BUTTONBAR_FILE )

(
  echo.%?~%: error: `Total Commander` button bar configuration file is not found: "%TOTALCMD_BUTTONBAR_FILE_PATH%".
  echo.
  exit /b 255
) >&2

:INSTALL_TOTALCMD_BUTTONBAR_FILE

set "TOTALCMD_CONFIG_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\totalcmd"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%" || (
  echo.%?~%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%".
  echo.
  exit /b 255
) >&2

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.totalcmd_prev_install\*" (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install\" "*.*" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%\" /E /Y || (
    echo.%?~%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.totalcmd_prev_install\" -^> "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\"
    echo.
    exit /b 255
  ) >&2
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/rmdir.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install" || exit /b 255
)

set "TOTALCMD_CONFIG_UNINSTALLED_DIR=%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\totalcmd_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%" || (
  echo.%?~%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_DIR%".
  echo.
  exit /b 255
) >&2

:INSTALL_TOTALCMD_BUTTONBAR_INI
if %WINDOWS_MAJOR_VER% GEQ 6 (
  if %INSTALL_SINGLE_BUTTON_MENU% EQU 0 (
    set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/_common/buttonbar6432.ini.in"
    if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/_common/buttonbar32.ini.in"
  ) else (
    set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/_common/buttonbar6432.ini.in"
    if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/_common/buttonbar32.ini.in"
  )
) else (
  if %INSTALL_SINGLE_BUTTON_MENU% EQU 0 (
    set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/winxp/buttonbar6432.ini.in"
    if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/winxp/buttonbar32.ini.in"
  ) else (
    set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/winxp/buttonbar6432.ini.in"
    if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/winxp/buttonbar32.ini.in"
  )
)
set "TOTALCMD_BUTTONBAR_INOUT_FILE=%TOTALCMD_BUTTONBAR_FILE_PATH%"
set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar_cleanup.ini"

for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_ADD_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_ADD_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_ADD_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_INOUT_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_INOUT_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_NAME=%%~nxi
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_CLEANUP_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_NAME=%%~nxi"

echo.Updating `Total Commander` button bar configuration file: "%TOTALCMD_BUTTONBAR_ADD_FILE%" -^> "%TOTALCMD_BUTTONBAR_INOUT_FILE%"...
echo.

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_DIR%%" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~%: error: backup of `Total Commander` button bar configuration file is failed.
  echo.
  exit /b 255
) >&2

set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{OS_SUFFIX}}" ""
if %WINDOWS_MAJOR_VER% EQU 5 set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{OS_SUFFIX}}" "_winxp"

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_buttonbar.vbs"%INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS% "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_CLEANUP_FILE%" "%TOTALCMD_BUTTONBAR_ADD_FILE%" -1 True || (
  echo.%?~%: error: update of `Total Commander` button bar configuration file is aborted.
  echo.
  exit /b 255
) >&2

exit /b 0
