@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" INSTALL_TO_DIR PROJECT_LOG_FILE_NAME_DATE_TIME TACKLEBAR_PROJECT_EXTERNALS_ROOT || exit /b

if "%DETECTED_TOTALCMD_PRODUCT_VERSION%" == "" (
  echo.%?~nx0%: error: `Total Commander` installation is not detected.
  echo.
  exit /b 255
) >&2

echo.Searching for `Total Commander` configuration files...
echo.

set "TOTALCMD_MAIN_CONFIG_DIR="
set "TOTALCMD_MAIN_CONFIG_FILE="
set "TOTALCMD_MAIN_CONFIG_FILE_NAME="
if defined COMMANDER_INI if exist "%COMMANDER_INI%" for /F "tokens=* delims="eol^= %%i in ("%COMMANDER_INI%\.") do set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi" & set "TOTALCMD_MAIN_CONFIG_DIR=%%~dpi" & set "TOTALCMD_MAIN_CONFIG_FILE_NAME=%%~nxi"

if defined TOTALCMD_MAIN_CONFIG_DIR ( set "TOTALCMD_MAIN_CONFIG_DIR=%TOTALCMD_MAIN_CONFIG_DIR:~0,-1%" & goto INSTALL_TOTALCMD_CONFIG_FILES )

rem CAUTION: We must avoid trailing slash here
if defined DETECTED_TOTALCMD_INI_FILE_DIR (
  for /F "tokens=* delims="eol^= %%i in ("%DETECTED_TOTALCMD_INI_FILE_DIR%\.") do set "SELECT_FILE_DIALOG_DIR=%%~fi"
) else for /F "tokens=* delims="eol^= %%i in ("%DETECTED_TOTALCMD_INSTALL_DIR%\.") do set "SELECT_FILE_DIALOG_DIR=%%~fi"

if not defined TOTALCMD_MAIN_CONFIG_DIR ^
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%CONTOOLS_UTILS_BIN_ROOT%/contools/wxFileDialog.exe" "" "%SELECT_FILE_DIALOG_DIR%" "Select Total Commander main configuration file (`main.ini` or `wincmd.ini`)..." -e`) do set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi"

if defined TOTALCMD_MAIN_CONFIG_FILE for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_MAIN_CONFIG_FILE%") do set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi" & set "TOTALCMD_MAIN_CONFIG_DIR=%%~dpi" & set "TOTALCMD_MAIN_CONFIG_FILE_NAME=%%~nxi"

if defined TOTALCMD_MAIN_CONFIG_DIR (
  set "TOTALCMD_MAIN_CONFIG_DIR=%TOTALCMD_MAIN_CONFIG_DIR:~0,-1%"
  goto INSTALL_TOTALCMD_CONFIG_FILES
) else (
  echo.%?~nx0%: error: `Total Commander` main configuration file ^(`main.ini` or `wincmd.ini`^) is not found or not selected.
  echo.
  exit /b 255
) >&2

:INSTALL_TOTALCMD_CONFIG_FILES

set "TOTALCMD_CONFIG_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\totalcmd"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%" || (
  echo.%?~nx0%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%".
  echo.
  exit /b 255
) >&2

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.totalcmd_prev_install\*" (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install\" "*.*" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%\" /E /Y || (
    echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.totalcmd_prev_install\" -^> "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\"
    echo.
    exit /b 255
  ) >&2
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/rmdir.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install" || exit /b 255
)

set "TOTALCMD_CONFIG_UNINSTALLED_DIR=%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\totalcmd_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%" || (
  echo.%?~nx0%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_DIR%".
  echo.
  exit /b 255
) >&2

:INSTALL_TOTALCMD_USERCMD_INI
set "TOTALCMD_USERCMD_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/usercmd.ini.in"
set "TOTALCMD_USERCMD_INOUT_FILE=%TOTALCMD_MAIN_CONFIG_DIR%/usercmd.ini"
set "TOTALCMD_USERCMD_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/usercmd_cleanup.ini"

for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_USERCMD_ADD_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_USERCMD_ADD_FILE=%%~fi" & set "TOTALCMD_USERCMD_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_ADD_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_USERCMD_INOUT_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_USERCMD_INOUT_FILE=%%~fi" & set "TOTALCMD_USERCMD_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_INOUT_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_USERCMD_CLEANUP_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_USERCMD_CLEANUP_FILE=%%~fi" & set "TOTALCMD_USERCMD_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_CLEANUP_FILE_NAME=%%~nxi"

echo.Updating `Total Commander` user configuration file: "%TOTALCMD_USERCMD_ADD_FILE%" -^> "%TOTALCMD_USERCMD_INOUT_FILE%"...
echo.

if not exist "%TOTALCMD_USERCMD_INOUT_FILE%" goto COPY_TOTALCMD_USERCMD_INI

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of `Total Commander` user configuration file is failed.
  echo.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_usercmd.vbs" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_CLEANUP_FILE%" "%TOTALCMD_USERCMD_ADD_FILE%" || (
  echo.%?~nx0%: error: update of `Total Commander` user configuration file is aborted.
  echo.
  exit /b 255
) >&2

goto END_INSTALL_TOTALCMD_USERCMD_INI

:COPY_TOTALCMD_USERCMD_INI
call "%%CONTOOLS_ROOT%%/std/xcopy_file_rename.bat"%%XCOPY_FILE_CMD_BARE_FLAGS%% "%%TOTALCMD_USERCMD_ADD_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_ADD_FILE_NAME%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" /Y /D /H || exit /b 255

echo.

:END_INSTALL_TOTALCMD_USERCMD_INI

:INSTALL_TOTALCMD_WINCMD_INI
set "TOTALCMD_WINCMD_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/wincmd.ini.in"
set "TOTALCMD_WINCMD_INOUT_FILE=%TOTALCMD_MAIN_CONFIG_FILE%"
set "TOTALCMD_WINCMD_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/wincmd_cleanup.ini"

for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_WINCMD_ADD_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_WINCMD_ADD_FILE=%%~fi" & set "TOTALCMD_WINCMD_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_ADD_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_WINCMD_INOUT_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_WINCMD_INOUT_FILE=%%~fi" & set "TOTALCMD_WINCMD_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_INOUT_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_WINCMD_CLEANUP_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_WINCMD_CLEANUP_FILE=%%~fi" & set "TOTALCMD_WINCMD_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_CLEANUP_FILE_NAME=%%~nxi"

echo.Updating `Total Commander` main configuration file: "%TOTALCMD_WINCMD_ADD_FILE%" -^> "%TOTALCMD_WINCMD_INOUT_FILE%"...
echo.

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TOTALCMD_WINCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of `Total Commander` main configuration file is failed.
  echo.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_wincmd.vbs" "%TOTALCMD_WINCMD_INOUT_FILE%" "%TOTALCMD_WINCMD_INOUT_FILE%" "%TOTALCMD_WINCMD_CLEANUP_FILE%" "%TOTALCMD_WINCMD_ADD_FILE%" || (
  echo.%?~nx0%: error: update of `Total Commander` main configuration file is aborted.
  echo.
  exit /b 255
) >&2

rem return variables
(
  endlocal
  set "DETECTED_TOTALCMD_USERCMD_CONFIG_FILE=%TOTALCMD_USERCMD_INOUT_FILE%"
  set "DETECTED_TOTALCMD_WINCMD_CONFIG_FILE=%TOTALCMD_WINCMD_INOUT_FILE%"
  exit /b 0
)
