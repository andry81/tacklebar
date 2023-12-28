@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

for %%i in (INSTALL_TO_DIR PROJECT_LOG_FILE_NAME_SUFFIX EMPTY_DIR_TMP) do (
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
if defined DETECTED_TOTALCMD_INI_FILE_DIR (
  for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_TOTALCMD_INI_FILE_DIR%\.") do set "SELECT_FILE_DIALOG_DIR=%%~fi"
) else for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_TOTALCMD_INSTALL_DIR%\.") do set "SELECT_FILE_DIALOG_DIR=%%~fi"

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

echo.Backuping Total Commander configuration files...

set "TOTALCMD_CONFIG_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\totalcmd"

if not exist "\\?\%TOTALCMD_CONFIG_UNINSTALLED_ROOT%" (
  call :MAKE_DIR "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%" || (
    echo.%?~nx0%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%".
    exit /b 255
  ) >&2
  echo.
)

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.totalcmd_prev_install\*" (
  call :XMOVE_FILE "%%INSTALL_TO_DIR%%\.totalcmd_prev_install\" "*.*" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%\" /E /Y || (
    echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.totalcmd_prev_install\" -^> "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\"
    exit /b 255
  ) >&2
  call :CMD rmdir "\\?\%INSTALL_TO_DIR%\.totalcmd_prev_install"
)

set "TOTALCMD_CONFIG_UNINSTALLED_DIR=%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\totalcmd_%PROJECT_LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%TOTALCMD_CONFIG_UNINSTALLED_DIR%" (
  call :MAKE_DIR "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%" || (
    echo.%?~nx0%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_DIR%".
    exit /b 255
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

call :XCOPY_FILE "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of Total Commander user configuration file is failed.
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_usercmd.vbs" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_INOUT_FILE%" "%TOTALCMD_USERCMD_CLEANUP_FILE%" "%TOTALCMD_USERCMD_ADD_FILE%" || (
  echo.%?~nx0%: error: update of Total Commander user configuration file is aborted.
  exit /b 255
) >&2

goto END_INSTALL_TOTALCMD_USERCMD_INI

:COPY_TOTALCMD_USERCMD_INI
call "%%CONTOOLS_ROOT%%/std/xcopy_file_rename.bat"%%XCOPY_FILE_CMD_BARE_FLAGS%% "%%TOTALCMD_USERCMD_ADD_FILE_DIR%%" "%%TOTALCMD_USERCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_USERCMD_ADD_FILE_NAME%%" "%%TOTALCMD_USERCMD_INOUT_FILE_NAME%%" /Y /D /H || exit /b 255

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

call :XCOPY_FILE "%%TOTALCMD_WINCMD_INOUT_FILE_DIR%%" "%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_WINCMD_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
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
if %INSTALL_SINGLE_BUTTON_MENU% EQU 0 (
  set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/buttonbar6432.ini.in"
  if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/multiple/buttonbar32.ini.in"
) else if %WINDOWS_MAJOR_VER% GEQ 6 (
  set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/_common/buttonbar6432.ini.in"
  if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/_common/buttonbar32.ini.in"
) else (
  set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/winxp/buttonbar6432.ini.in"
  if %WINDOWS_X64_VER%0 EQU 0 set "TOTALCMD_BUTTONBAR_ADD_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/single/winxp/buttonbar32.ini.in"
)
set "TOTALCMD_BUTTONBAR_INOUT_FILE=%TOTALCMD_BUTTONBAR_FILE_PATH%"
set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar_cleanup.ini"

for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_ADD_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_ADD_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_ADD_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_INOUT_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_INOUT_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TOTALCMD_BUTTONBAR_CLEANUP_FILE%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do ( set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_NAME=%%~nxi" )

echo.Updating Total Commander button bar configuration file: "%TOTALCMD_BUTTONBAR_ADD_FILE%" -^> "%TOTALCMD_BUTTONBAR_INOUT_FILE%"...
echo.

call :XCOPY_FILE "%%TOTALCMD_BUTTONBAR_INOUT_FILE_DIR%%" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo.%?~nx0%: error: backup of Total Commander button bar configuration file is failed.
  exit /b 255
) >&2

set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{OS_SUFFIX}}" ""
if %WINDOWS_MAJOR_VER% EQU 5 set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{OS_SUFFIX}}" "_winxp"

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_buttonbar.vbs"%INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS% "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_CLEANUP_FILE%" "%TOTALCMD_BUTTONBAR_ADD_FILE%" -1 True || (
  echo.%?~nx0%: error: update of Total Commander button bar configuration file is aborted.
  exit /b 255
) >&2

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3\*" (
  call :MAKE_DIR "%%~3" || exit /b
  echo.
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat"%%XCOPY_FILE_CMD_BARE_FLAGS%% %%*
exit /b

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

echo.^>mkdir "%FILE_PATH%"
mkdir "%FILE_PATH%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul ) else type 2>nul || (
  echo.%?~nx0%: error: could not create a target file directory: "%FILE_PATH%".
  exit /b 255
) >&2
exit /b

:XMOVE_FILE
call "%%CONTOOLS_ROOT%%/std/xmove_file.bat"%%XMOVE_FILE_CMD_BARE_FLAGS%% %%*
exit /b

:XMOVE_DIR
call "%%CONTOOLS_ROOT%%/std/xmove_dir.bat"%%XMOVE_DIR_CMD_BARE_FLAGS%% %%*
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b
