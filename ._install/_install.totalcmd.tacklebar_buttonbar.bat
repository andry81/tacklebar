@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" INSTALL_TO_DIR PROJECT_LOG_FILE_NAME_DATE_TIME TACKLEBAR_PROJECT_EXTERNALS_ROOT || exit /b

if "%DETECTED_TOTALCMD_PRODUCT_VERSION%" == "" (
  echo;%?~%: error: `Total Commander` installation is not detected.
  echo;
  exit /b 255
) >&2

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" DETECTED_TOTALCMD_WINCMD_CONFIG_FILE || exit /b

echo;Searching for `Total Commander` buttonbar file(s)...
echo;

set "TOTALCMD_BUTTONBAR_FILE_PATH="
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/get_inifile_key.vbs" "%DETECTED_TOTALCMD_WINCMD_CONFIG_FILE%" "Buttonbar" "Buttonbar"`) do set "TOTALCMD_BUTTONBAR_FILE_PATH=%%i"

rem list of ButtorBar files to update
set "TOTALCMD_BUTTONBAR_FILE_PATH_LIST="
if defined TOTALCMD_BUTTONBAR_FILE_PATH if exist "%TOTALCMD_BUTTONBAR_FILE_PATH%" set TOTALCMD_BUTTONBAR_FILE_PATH_LIST="%TOTALCMD_BUTTONBAR_FILE_PATH%" & goto INSTALL_TOTALCMD_BUTTONBAR_FILE_LIST

rem search in the Total Commander installation directory
if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR" set TOTALCMD_BUTTONBAR_FILE_PATH_LIST=%TOTALCMD_BUTTONBAR_FILE_PATH_LIST% "%DETECTED_TOTALCMD_INSTALL_DIR%\DEFAULT.BAR"

rem search in the APPDATA directory
if defined APPDATA if exist "%APPDATA%\GHISLER\DEFAULT.BAR" set TOTALCMD_BUTTONBAR_FILE_PATH_LIST=%TOTALCMD_BUTTONBAR_FILE_PATH_LIST% "%APPDATA%\GHISLER\DEFAULT.BAR"

rem search in the LOCALAPPDATA directory
if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\GHISLER\DEFAULT.BAR" set TOTALCMD_BUTTONBAR_FILE_PATH_LIST=%TOTALCMD_BUTTONBAR_FILE_PATH_LIST% "%LOCALAPPDATA%\GHISLER\DEFAULT.BAR"

if defined TOTALCMD_BUTTONBAR_FILE_PATH_LIST goto INSTALL_TOTALCMD_BUTTONBAR_FILE_LIST

(
  echo;%?~%: error: `Total Commander` button bar configuration file is not found: "%TOTALCMD_BUTTONBAR_FILE_PATH_LIST%".
  echo;
  exit /b 255
) >&2

:INSTALL_TOTALCMD_BUTTONBAR_FILE_LIST

for %%i in (%TOTALCMD_BUTTONBAR_FILE_PATH_LIST%) do echo;  * %%i
echo;

set "TOTALCMD_CONFIG_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\totalcmd"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%" || (
  echo;%?~%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%".
  echo;
  exit /b 255
) >&2

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.totalcmd_prev_install\*" (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install\" "*.*" "%%TOTALCMD_CONFIG_UNINSTALLED_ROOT%%\" /E /Y || (
    echo;%?~%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.totalcmd_prev_install\" -^> "%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\"
    echo;
    exit /b 255
  ) >&2
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/rmdir.bat" "%%INSTALL_TO_DIR%%\.totalcmd_prev_install" || (
    echo;
    exit /b 255
  ) >&2
)

set "TOTALCMD_CONFIG_UNINSTALLED_DIR=%TOTALCMD_CONFIG_UNINSTALLED_ROOT%\totalcmd_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%" || (
  echo;%?~%: error: could not create a backup file directory: "%TOTALCMD_CONFIG_UNINSTALLED_DIR%".
  echo;
  exit /b 255
) >&2

echo;Installing `Tacklebar` buttonbar files...
echo;

set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{WINVER_SUFFIX_SPEC}}" ""
set GEN_CONFIG_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rm "{{WINVER_SUFFIX_SPEC}}"

rem copy common button bar files
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/_common" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL

rem copy System32/System64 dependent files
if %WINDOWS_X64_VER% NEQ 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/win/sys64" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL
) else call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/win/sys32" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL

rem copy Windows version specialized files
if %WINDOWS_MAJOR_VER% EQU 5 (
  rem rewrite files even if were newer
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/winxp" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y || goto CANCEL_INSTALL

  set INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS= -rep "{{WINVER_SUFFIX_SPEC}}" "_winxp"
  set GEN_CONFIG_TOTALCMD_BUTTONBAR_BARE_FLAGS= -r "{{WINVER_SUFFIX_SPEC}}" "_winxp"
)

set "WINDOWS_MAJOR_VER_STR=0%WINDOWS_MAJOR_VER%"
set "WINDOWS_MINOR_VER_STR=0%WINDOWS_MINOR_VER%"

if "%WINDOWS_MAJOR_VER_STR:~1,1%" == "" set "WINDOWS_MAJOR_VER_STR=0%WINDOWS_MAJOR_VER_STR%"
if "%WINDOWS_MINOR_VER_STR:~1,1%" == "" set "WINDOWS_MINOR_VER_STR=0%WINDOWS_MINOR_VER_STR%"

rem locate windows ico file name
set "APP_WINDOWS_ICO_FILES_DIR=%TACKLEBAR_PROJECT_ROOT%\res\images\app\windows"
set "APP_WINDOWS_ICO_FILE_PATH_GLOB=%APP_WINDOWS_ICO_FILES_DIR%\%WINDOWS_MAJOR_VER_STR%_%WINDOWS_MINOR_VER_STR%_*.ico"

set "LOCATED_APP_WINDOWS_ICO_FILE_NAME="
for %%i in ("%APP_WINDOWS_ICO_FILE_PATH_GLOB%") do set "LOCATED_APP_WINDOWS_ICO_FILE_NAME=%%~nxi" & goto LOCATE_APP_WINDOWS_ICO_FILE_NAME_END

rem find closest version (greater)
set ?.=@dir "%APP_WINDOWS_ICO_FILES_DIR%\*_*_*.ico" /A:-D /B /O:N 2^>nul

for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do set "APP_WINDOWS_ICO_FILE_NAME=%%i" & call :LOCATE_CLOSEST_APP_WINDOWS_ICO_FILE_NAME & if defined LOCATED_APP_WINDOWS_ICO_FILE_NAME goto LOCATE_APP_WINDOWS_ICO_FILE_NAME_END

(
  echo;%?~%: error: could not locate file: "%APP_WINDOWS_ICO_FILE_PATH_GLOB%".
  echo;
  exit /b 255
) >&2

:LOCATE_CLOSEST_APP_WINDOWS_ICO_FILE_NAME
for /F "tokens=1,2 delims=_"eol^= %%i in ("%APP_WINDOWS_ICO_FILE_NAME%") do (
  if %%i EQU %WINDOWS_MAJOR_VER% if %%j GEQ %WINDOWS_MINOR_VER% set "LOCATED_APP_WINDOWS_ICO_FILE_NAME=%APP_WINDOWS_ICO_FILE_NAME%" & exit /b 0
  if %%i GTR %WINDOWS_MAJOR_VER% set "LOCATED_APP_WINDOWS_ICO_FILE_NAME=%APP_WINDOWS_ICO_FILE_NAME%" & exit /b 0
)
exit /b 0

:LOCATE_APP_WINDOWS_ICO_FILE_NAME_END

set GEN_CONFIG_TOTALCMD_BUTTONBAR_BARE_FLAGS=%GEN_CONFIG_TOTALCMD_BUTTONBAR_BARE_FLAGS% -r "{{WINDOWS_ICO_FILE_NAME}}" "%LOCATED_APP_WINDOWS_ICO_FILE_NAME%"

rem generate `*.bar` files from `*.bar.in` files recursively
set ?.=@dir "%INSTALL_TO_DIR%\tacklebar\ButtonBars\*.bar.in" /A:-D /B /O:N /S 2^>nul

rem ignore `*.bar.in` file if respective `*.bar` file already existed
for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do if not exist "%%~dpni" ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_BUILD_TOOLS_ROOT%%/gen_config.bat"%%GEN_CONFIG_TOTALCMD_BUTTONBAR_BARE_FLAGS%% "%%~dpi" "%%~dpi" "%%~ni" || (
  echo;%?~%: error: could not generate configuration file in the installation directory: "%%i" -^> "%%~dpni"
  echo;
  exit /b 255
) >&2

echo;

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

set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%TACKLEBAR_PROJECT_ROOT%/deploy/totalcmd/Profile/buttonbar_cleanup.ini"

for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_ADD_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_ADD_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_ADD_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_ADD_FILE_NAME=%%~nxi"
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_CLEANUP_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_CLEANUP_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_CLEANUP_FILE_NAME=%%~nxi"

for %%i in (%TOTALCMD_BUTTONBAR_FILE_PATH_LIST%) do set "TOTALCMD_BUTTONBAR_INOUT_FILE=%%~i" & call :INSTALL_TOTALCMD_BUTTONBAR_FILE

goto INSTALL_TOTALCMD_BUTTONBAR_FILE_END

:INSTALL_TOTALCMD_BUTTONBAR_FILE
for /F "tokens=* delims="eol^= %%i in ("%TOTALCMD_BUTTONBAR_INOUT_FILE%\.") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TOTALCMD_BUTTONBAR_INOUT_FILE=%%~fi" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_DIR=%%~fj" & set "TOTALCMD_BUTTONBAR_INOUT_FILE_NAME=%%~nxi

echo;Updating `Total Commander` button bar configuration file: "%TOTALCMD_BUTTONBAR_ADD_FILE%" -^> "%TOTALCMD_BUTTONBAR_INOUT_FILE%"...
echo;

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_DIR%%" "%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%" "%%TOTALCMD_CONFIG_UNINSTALLED_DIR%%/%%TOTALCMD_BUTTONBAR_INOUT_FILE_NAME%%~%%RANDOM%%" /Y /D /H || (
  echo;%?~%: error: backup of `Total Commander` button bar configuration file is failed.
  echo;
  exit /b 255
) >&2

"%SystemRoot%\System32\cscript.exe" /NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/totalcmd/install_totalcmd_buttonbar.vbs"%INSTALL_TOTALCMD_BUTTONBAR_BARE_FLAGS% "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_INOUT_FILE%" "%TOTALCMD_BUTTONBAR_CLEANUP_FILE%" "%TOTALCMD_BUTTONBAR_ADD_FILE%" -1 True || (
  echo;%?~%: error: update of `Total Commander` button bar configuration file is aborted.
  echo;
  exit /b 255
) >&2

echo;

:INSTALL_TOTALCMD_BUTTONBAR_FILE_END

exit /b 0
