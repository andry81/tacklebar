@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" CONTOOLS_ROOT CONTOOLS_UTILS_BIN_ROOT || exit /b

rem script flags
set FLAG_UPDATE_SCREEN_SIZE=0
set FLAG_UPDATE_BUFFER_SIZE=0
set FLAG_UPDATE_REGISTRY=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-update_screen_size" (
    set FLAG_UPDATE_SCREEN_SIZE=1
  ) else if "%FLAG%" == "-update_buffer_size" (
    set FLAG_UPDATE_BUFFER_SIZE=1
  ) else if "%FLAG%" == "-update_registry" (
    set FLAG_UPDATE_REGISTRY=1
  ) else (
    echo.%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

rem drop last error level
call;

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!
rem
for /F "usebackq tokens=1,2,* delims=[]" %%i in (`ver`) do for /F "tokens=1,2,* delims= " %%l in ("%%j") do set "WINDOWS_VER_STR=%%m"

set WINDOWS_MAJOR_VER=0
set WINDOWS_MINOR_VER=0
for /F "tokens=1,2,* delims=."eol^= %%i in ("%WINDOWS_VER_STR%") do set "WINDOWS_MAJOR_VER=%%i" & set "WINDOWS_MINOR_VER=%%j"

set WINDOWS_X64_VER=0
if defined PROCESSOR_ARCHITEW6432 ( set "WINDOWS_X64_VER=1" ) else if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set WINDOWS_X64_VER=1

rem calibrate terminal screen size at first

rem display resolution  -> terminal screen size
rem   800 x 600         -> 105 x 40
rem  1024 x 768         -> 120 x 50
rem  1920 x 1080        -> 140 x 60
rem  2560 x 1440        -> 180 x 75

rem minimal size
set "TERMINAL_SCREEN_WIDTH=105"
set "TERMINAL_SCREEN_HEIGHT=40"
set "TERMINAL_SCREEN_SIZE=0x00280069"

set "TERMINAL_SCREEN_BUFFER_HEIGHT=32766"
set "TERMINAL_SCREEN_BUFFER_SIZE=0x7ffe0069"

call "%%CONTOOLS_WMI_ROOT%%\get_wmic_first_display_resolution.bat"

set DISPLAY_WIDTH=0
set DISPLAY_HEIGHT=0
for /F "tokens=1,2 delims=|"eol^= %%i in ("%RETURN_VALUE%") do set "DISPLAY_WIDTH=%%i" & set "DISPLAY_HEIGHT=%%j"

if %DISPLAY_WIDTH% GEQ 2560 if %DISPLAY_HEIGHT% GEQ 1440 (
  set "TERMINAL_SCREEN_WIDTH=180"
  set "TERMINAL_SCREEN_HEIGHT=75"
  set "TERMINAL_SCREEN_SIZE=0x004b00b4"
  set "TERMINAL_SCREEN_BUFFER_SIZE=0x7ffe00b4"
  goto FIND_TERMINAL_SCREEN_SIZE_END
)

if %DISPLAY_WIDTH% GEQ 1920 if %DISPLAY_HEIGHT% GEQ 1080 (
  set "TERMINAL_SCREEN_WIDTH=140"
  set "TERMINAL_SCREEN_HEIGHT=60"
  set "TERMINAL_SCREEN_SIZE=0x003c008c"
  set "TERMINAL_SCREEN_BUFFER_SIZE=0x7ffe008c"
  goto FIND_TERMINAL_SCREEN_SIZE_END
)

if %DISPLAY_WIDTH% GEQ 1024 if %DISPLAY_HEIGHT% GEQ 768 (
  set "TERMINAL_SCREEN_WIDTH=120"
  set "TERMINAL_SCREEN_HEIGHT=50"
  set "TERMINAL_SCREEN_SIZE=0x00320078"
  set "TERMINAL_SCREEN_BUFFER_SIZE=0x7ffe0078"
  goto FIND_TERMINAL_SCREEN_SIZE_END
)

:FIND_TERMINAL_SCREEN_SIZE_END

if %FLAG_UPDATE_BUFFER_SIZE% EQU 0 goto UPDATE_BUFFER_SIZE_END

echo.Updating terminal buffer sizes...
echo.

"%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/fpwestlake-conutils/ConSetBuffer.exe" "/X=%TERMINAL_SCREEN_WIDTH%" "/Y=%TERMINAL_SCREEN_BUFFER_HEIGHT%"

:UPDATE_BUFFER_SIZE_END

if %FLAG_UPDATE_SCREEN_SIZE% EQU 0 goto UPDATE_SCREEN_SIZE_END

echo.Updating terminal screen sizes...
echo.

rem apply terminal window size before registry write

rem CAUTION:
rem   Clears the sreen and resets the buffer sizes
rem
rem mode con: cols=%TERMINAL_SCREEN_WIDTH% lines=%TERMINAL_SCREEN_HEIGHT%

rem NOTE:
rem   Call with `/L=0` parameter to avoid scrollbars appear
rem

set /A TERMINAL_SCREEN_RIGHT_POS=TERMINAL_SCREEN_WIDTH-1

"%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/fpwestlake-conutils/ConSetWindow.exe" "/L=0" "/T=1" "/B=%TERMINAL_SCREEN_HEIGHT%" "/R=%TERMINAL_SCREEN_RIGHT_POS%"

:UPDATE_SCREEN_SIZE_END

if %FLAG_UPDATE_SCREEN_SIZE% NEQ 0 (
  echo.* TERMINAL_SCREEN_WIDTH=%TERMINAL_SCREEN_WIDTH%
  echo.* TERMINAL_SCREEN_HEIGHT=%TERMINAL_SCREEN_HEIGHT%
  echo.
)

if %FLAG_UPDATE_BUFFER_SIZE% NEQ 0 (
  echo.* TERMINAL_SCREEN_BUFFER_WIDTH=%TERMINAL_SCREEN_WIDTH%
  echo.* TERMINAL_SCREEN_BUFFER_HEIGHT=%TERMINAL_SCREEN_BUFFER_HEIGHT%
  echo.
)

if %FLAG_UPDATE_REGISTRY% EQU 0 goto UPDATE_CONSOLE_REGISTRY_PARAMS_END

if %WINDOWS_MAJOR_VER% EQU 5 (
  rem check for true elevated environment (required in case of Windows XP)
  call "%%CONTOOLS_ROOT%%/std/is_admin_elevated.bat" || (
    echo.%?~%: error: the script process is not properly elevated up to Administrator privileges.
    goto UPDATE_CONSOLE_REGISTRY_PARAMS_END
  ) >&2
)

echo.Updating terminal font...
echo.

set "TERMINAL_FONT_NAME=Lucida Console"

set "CMD_TERMINAL_FONT_FAMILY=0x36"
set "CMD_TERMINAL_FONT_WEIGHT=0x190"

set "CONEMU_TERMINAL_FONT_SIZE=0x50000"

rem must 3 for complete registration
set FONT_TERMINAL_VECTOR_REGISTER_FOR_CONSOLE=0
set FONT_TERMINAL_VECTOR_REGISTER_IN_FONTS=0
set FONT_TERMINAL_VECTOR_COPIED_TO_FONTS_DIR=0

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -posparam "0,1" "TerminalVector" -posparam "2,3" "TerminalVector (TrueType)" ^
  "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" ^
  "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Fonts"`) do (
  set "PARAM_NAME=%%j"
  set "PARAM_VALUE=%%k"
  call :FIND_FONT && goto FIND_FONT_END
)

goto FIND_FONT_END

:FIND_FONT
if "%PARAM_NAME%" == "TerminalVector" if not "%PARAM_VALUE%" == "." set FONT_TERMINAL_VECTOR_REGISTER_FOR_CONSOLE=1
if "%PARAM_NAME%" == "TerminalVector (TrueType)" if not "%PARAM_VALUE%" == "." (
  set FONT_TERMINAL_VECTOR_REGISTER_IN_FONTS=1
  if exist "%SystemRoot%\Fonts\%PARAM_VALUE%" set FONT_TERMINAL_VECTOR_COPIED_TO_FONTS_DIR=1
)

if %FONT_TERMINAL_VECTOR_REGISTER_FOR_CONSOLE%%FONT_TERMINAL_VECTOR_REGISTER_IN_FONTS%%FONT_TERMINAL_VECTOR_COPIED_TO_FONTS_DIR% EQU 111 ( set "TERMINAL_FONT_NAME=TerminalVector" & exit /b 0 )

exit /b 1

:FIND_FONT_END

rem Lucida Console
set "CMD_TERMINAL_FONT_SIZE0=0xC0007"
rem Terminal Vector
set "CMD_TERMINAL_FONT_SIZE1=0xC0008"

set "CMD_TERMINAL_BASIC_FONT_NAME="

if %WINDOWS_X64_VER%0 NEQ 0 (
  for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
    "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param_per_line -param "FaceName" -param "ScreenBufferSize" -u ^
    "HKCU\Console" ^
    "HKCU\Console\%%25SystemRoot%%25_System32_cmd.exe" ^
    "HKCU\Console\%%25SystemRoot%%25_System64_cmd.exe" ^
    "HKCU\Console\%%25SystemRoot%%25_SysWOW64_cmd.exe" ^
    "HKCU\Console\%%25SystemRoot%%25_Sysnative_cmd.exe" ^
    "HKCU\Console\ConEmu"`) do (
    set "PARAM_HKEY=%%i"
    set "PARAM_NAME=%%j"
    set "PARAM_VALUE=%%k"
    call :UPDATE_CONSOLE_REGISTRY_PARAMS
  )
) else for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param_per_line -param "FaceName" -param "ScreenBufferSize" -u ^
  "HKCU\Console" ^
  "HKCU\Console\%%25SystemRoot%%25_System32_cmd.exe" ^
  "HKCU\Console\ConEmu"`) do (
  set "PARAM_HKEY=%%i"
  set "PARAM_NAME=%%j"
  set "PARAM_VALUE=%%k"
  call :UPDATE_CONSOLE_REGISTRY_PARAMS
)

echo.

goto UPDATE_CONSOLE_REGISTRY_PARAMS_END

:UPDATE_CONSOLE_REGISTRY_PARAMS

if not "%PARAM_NAME%" == "FaceName" goto UPDATE_SCREEN_BUFFER_SIZE

set "CMD_TERMINAL_FONT_NAME="

"%System6432%\reg.exe" add "%PARAM_HKEY%" /f >nul 2>nul

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%PARAM_HKEY%%" "FaceName" >nul 2>nul
if defined REGQUERY_VALUE set "CMD_TERMINAL_FONT_NAME=%REGQUERY_VALUE%"

if /i "%PARAM_HKEY%" == "HKCU\Console" (
  set "CMD_TERMINAL_BASIC_FONT_NAME=%CMD_TERMINAL_FONT_NAME%"
)

if not defined CMD_TERMINAL_BASIC_FONT_NAME if "%PARAM_VALUE%" == "." (
  "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FaceName /t REG_SZ /d "%TERMINAL_FONT_NAME%" /f >nul
)

if not "%PARAM_HKEY%" == "HKCU\Console\ConEmu" (
  if not defined CMD_TERMINAL_BASIC_FONT_NAME if "%PARAM_VALUE%" == "." (
    "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FontFamily /t REG_DWORD /d "%CMD_TERMINAL_FONT_FAMILY%" /f >nul
    if /i "%TERMINAL_FONT_NAME%" == "TerminalVector" (
      "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FontSize /t REG_DWORD /d "%CMD_TERMINAL_FONT_SIZE1%" /f >nul
    ) else "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FontSize /t REG_DWORD /d "%CMD_TERMINAL_FONT_SIZE0%" /f >nul
    "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FontWeight /t REG_DWORD /d "%CMD_TERMINAL_FONT_WEIGHT%" /f >nul
  )
) else (
  if not defined CMD_TERMINAL_BASIC_FONT_NAME if "%PARAM_VALUE%" == "." (
    "%System6432%\reg.exe" add "%PARAM_HKEY%" /v FontSize /t REG_DWORD /d "%CONEMU_TERMINAL_FONT_SIZE%" /f >nul
  )
)

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%PARAM_HKEY%%" "FaceName" >nul 2>nul
if defined REGQUERY_VALUE set "CMD_TERMINAL_FONT_NAME=%REGQUERY_VALUE%"

echo.* [%PARAM_HKEY%] TERMINAL_FONT_NAME="%CMD_TERMINAL_FONT_NAME%"

:UPDATE_SCREEN_BUFFER_SIZE

if not "%PARAM_NAME%" == "ScreenBufferSize" goto UPDATE_SCREEN_BUFFER_SIZE_END

rem if empty or default (0x012c0050)
if "%PARAM_VALUE%" == "." (
  "%System6432%\reg.exe" add "%PARAM_HKEY%" /v ScreenBufferSize /t REG_DWORD /d "%TERMINAL_SCREEN_BUFFER_SIZE%" /f >nul
  "%System6432%\reg.exe" add "%PARAM_HKEY%" /v WindowSize /t REG_DWORD /d "%TERMINAL_SCREEN_SIZE%" /f >nul
) else if /i "%PARAM_VALUE%" == "19660880" (
  "%System6432%\reg.exe" add "%PARAM_HKEY%" /v ScreenBufferSize /t REG_DWORD /d "%TERMINAL_SCREEN_BUFFER_SIZE%" /f >nul
  "%System6432%\reg.exe" add "%PARAM_HKEY%" /v WindowSize /t REG_DWORD /d "%TERMINAL_SCREEN_SIZE%" /f >nul
)

:UPDATE_SCREEN_BUFFER_SIZE_END

exit /b 0

:UPDATE_CONSOLE_REGISTRY_PARAMS_END

(
  endlocal
  set "TERMINAL_SCREEN_WIDTH=%TERMINAL_SCREEN_WIDTH%"
  set "TERMINAL_SCREEN_HEIGHT=%TERMINAL_SCREEN_HEIGHT%"
  set "TERMINAL_SCREEN_BUFFER_HEIGHT=%TERMINAL_SCREEN_BUFFER_HEIGHT%"
  exit /b 0
)
