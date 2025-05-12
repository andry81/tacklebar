@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" ^
  CONTOOLS_ROOT CONTOOLS_UTILS_BIN_ROOT ^
  CMD_TERMINAL_FONT_FAMILY CMD_TERMINAL_FONT_SIZE0 CMD_TERMINAL_FONT_SIZE1 CMD_TERMINAL_FONT_WEIGHT ^
  CONEMU_TERMINAL_FONT_SIZE ^
  TERMINAL_FONT_NAME TERMINAL_SCREEN_BUFFER_SIZE TERMINAL_SCREEN_SIZE ^
  PARAM_HKEY PARAM_NAME PARAM_VALUE || exit /b

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

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

echo;* [%PARAM_HKEY%] TERMINAL_FONT_NAME="%CMD_TERMINAL_FONT_NAME%"

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
