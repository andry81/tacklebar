@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT ^
  INSTALL_TO_DIR LOG_FILE_NAME_SUFFIX EMPTY_DIR_TMP) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

echo.Searching for Total Commander configuration files...

set "TOTALCMD_MAIN_CONFIG_DIR="
set "TOTALCMD_MAIN_CONFIG_FILE="
set "TOTALCMD_MAIN_CONFIG_FILE_NAME="
if defined COMMANDER_INI if exist "%COMMANDER_INI%" for /F "eol= tokens=* delims=" %%i in ("%COMMANDER_INI%\.") do ( set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi" & set "TOTALCMD_MAIN_CONFIG_DIR=%%~dpi" & set "TOTALCMD_MAIN_CONFIG_FILE_NAME=%%~nxi" )

if defined TOTALCMD_MAIN_CONFIG_DIR ( set "TOTALCMD_MAIN_CONFIG_DIR=%TOTALCMD_MAIN_CONFIG_DIR:~0,-1%" & goto INSTALL_TOTALCMD_CONFIG_FILES )

rem CAUTION: We must avoid trailing slash here
for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_TOTALCMD_INSTALL_DIR%\.") do set "SELECT_FILE_DIALOG_DIR=%%~fi"

if not defined TOTALCMD_MAIN_CONFIG_DIR ^
for /F "usebackq eol=	 tokens=* delims=" %%i in (`@"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/wxFileDialog.exe" "" "%SELECT_FILE_DIALOG_DIR%" "Select Total Commander main configuration file (`main.ini` or `wincmd.ini`)..." -e`) do set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi"

if defined TOTALCMD_MAIN_CONFIG_FILE for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_MAIN_CONFIG_FILE%") do ( set "TOTALCMD_MAIN_CONFIG_FILE=%%~fi" & set "TOTALCMD_MAIN_CONFIG_DIR=%%~dpi" & set "TOTALCMD_MAIN_CONFIG_FILE_NAME=%%~nxi" )

if defined TOTALCMD_MAIN_CONFIG_DIR (
  set "TOTALCMD_MAIN_CONFIG_DIR=%TOTALCMD_MAIN_CONFIG_DIR:~0,-1%"
  goto INSTALL_TOTALCMD_CONFIG_FILES
) else (
  echo.%?~nx0%: error: Total Commander main configuration file ^(`main.ini` or `wincmd.ini`^) is not found or not selected.
  exit /b 255
) >&2

:INSTALL_TOTALCMD_CONFIG_FILES

echo.

rem backup going to be changed Total Commander configuration files
set "NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR=%INSTALL_TO_DIR%\.totalcmd_prev_install\totalcmd_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%" (
  echo.^>mkdir "%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%"
  mkdir "%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%" 2>nul || "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%" >nul
  if not exist "\\?\%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%".
    exit /b 30
  ) >&2
  echo.
)

:INSTALL_TOTALCMD_USERCMD_INI
set "TOTALCMD_USERCMD_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/usercmd.ini.in"
set "TOTALCMD_USERCMD_INOUT_FILE=%TOTALCMD_MAIN_CONFIG_DIR%/usercmd.ini"
set "TOTALCMD_USERCMD_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/usercmd_cleanup.ini"

for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_USERCMD_ADD_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_USERCMD_ADD_FILE=%%~fi" & set "TOTALCMD_USERCMD_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_ADD_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_USERCMD_INOUT_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_USERCMD_INOUT_FILE=%%~fi" & set "TOTALCMD_USERCMD_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_INOUT_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_USERCMD_CLEANUP_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_USERCMD_CLEANUP_FILE=%%~fi" & set "TOTALCMD_USERCMD_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_USERCMD_CLEANUP_FILE_NAME=%%~nxi" )

echo.Updating Total Commander user configuration file: "%TOTALCMD_USERCMD_ADD_FILE%" -^> "%TOTALCMD_USERCMD_INOUT_FILE%"...
echo.

if not exist "%TOTALCMD_USERCMD_INOUT_FILE%" goto COPY_TOTALCMD_USERCMD_INI

call :XCOPY_FILE "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" "%%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%%/%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of Total Commander user configuration file is failed.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_usercmd.vbs" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_CLEANUP_FILE%" "%TOTALCMD_USERCMD_ADD_FILE%" || (
  echo.%?~nx0%: error: update of Total Commander user configuration file is aborted.
  exit /b 255
) >&2

goto END_INSTALL_TOTALCMD_USERCMD_INI

:COPY_TOTALCMD_USERCMD_INI
call "%%CONTOOLS_ROOT%%/std/xcopy_file_rename.bat" "%%TOTALCMD_USERCMD_ADD_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_ADD_FILE_NAME%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" /Y /D /H || exit /b 255

:END_INSTALL_TOTALCMD_USERCMD_INI

echo.

:INSTALL_TOTALCMD_WINCMD_INI
set "TOTALCMD_WINCMD_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/wincmd.ini.in"
set "TOTALCMD_WINCMD_INOUT_FILE=%TOTALCMD_MAIN_CONFIG_FILE%"
set "TOTALCMD_WINCMD_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/wincmd_cleanup.ini"

for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_WINCMD_ADD_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_WINCMD_ADD_FILE=%%~fi" & set "TOTALCMD_WINCMD_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_ADD_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_WINCMD_INOUT_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_WINCMD_INOUT_FILE=%%~fi" & set "TOTALCMD_WINCMD_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_INOUT_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_WINCMD_CLEANUP_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_WINCMD_CLEANUP_FILE=%%~fi" & set "TOTALCMD_WINCMD_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_WINCMD_CLEANUP_FILE_NAME=%%~nxi" )

echo.Updating Total Commander main configuration file: "%TOTALCMD_WINCMD_ADD_FILE%" -^> "%TOTALCMD_WINCMD_INOUT_FILE%"...
echo.

set "TOTALCMD_BUTTONBAR_FILE_PATH="
for /F "usebackq eol= tokens=* delims=" %%i in (`@"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/get_inifile_key.vbs" "%TOTALCMD_WINCMD_INOUT_FILE%" "Buttonbar" "Buttonbar"`) do set "TOTALCMD_BUTTONBAR_FILE_PATH=%%i"

call :XCOPY_FILE "%%TOTALCMD_WINCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%" "%%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%%/%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of Total Commander main configuration file is failed.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_wincmd.vbs" "%TOTALCMD_WINCMD_INOUT_FILE%" "%TOTALCMD_WINCMD_INOUT_FILE%" "%TOTALCMD_WINCMD_CLEANUP_FILE%" "%TOTALCMD_WINCMD_ADD_FILE%" || (
  echo.%?~nx0%: error: update of Total Commander main configuration file is aborted.
  exit /b 255
) >&2

if defined TOTALCMD_BUTTONBAR_FILE_PATH if exist "%TOTALCMD_BUTTONBAR_FILE_PATH%" goto END_INSTALL_TOTALCMD_WINCMD_INI

rem search in the Total Commander installation directory
if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR" ( set "TOTALCMD_BUTTONBAR_FILE_PATH=%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR" & goto END_INSTALL_TOTALCMD_WINCMD_INI )

(
  echo.%?~nx0%: error: Total Commander button bar configuration file is not found: "%TOTALCMD_BUTTONBAR_FILE_PATH%".
  exit /b 255
) >&2

:END_INSTALL_TOTALCMD_WINCMD_INI

echo.

:INSTALL_TOTALCMD_BUTTONBAR_INI
set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar6432.ini.in"
if /i "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar32.ini.in"
set "TOTALCMD_BUTTONBAR_INOUT_FILE=%TOTALCMD_BUTTONBAR_FILE_PATH%"
set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar_cleanup.ini"

for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_ADD_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_ADD_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_ADD_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_INOUT_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_INOUT_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_CLEANUP_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_NAME=%%~nxi" )

echo.Updating Total Commander button bar configuration file: "%TOTALCMD_BUTTONBAR_ADD_FILE%" -^> "%TOTALCMD_BUTTONBAR_INOUT_FILE%"...
echo.

call :XCOPY_FILE "%%TOTALCMD_BUTTONBAR_INOUT_FILE_DIR%%" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%" "%%NEW_PREV_TOTALCMD_CONFIG_INSTALL_DIR%%/%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of Total Commander button bar configuration file is failed.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_buttonbar.vbs" "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_CLEANUP_FILE%" "%TOTALCMD_BUTTONBAR_ADD_FILE%" -1 True || (
  echo.%?~nx0%: error: update of Total Commander button bar configuration file is aborted.
  exit /b 255
) >&2

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3" (
  echo.^>mkdir "%~3"
  mkdir "%~3" 2>nul || "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~3" >nul || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
  echo.
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
exit /b
