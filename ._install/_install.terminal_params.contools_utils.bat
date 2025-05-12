@echo off

setlocal DISABLEDELAYEDEXPANSION

rem CAUTION: must be already reinitialized using `%%INSTALL_TO_DIR%%/tacklebar/__init__/__init__.bat` script
call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" CONTOOLS_ROOT CONTOOLS_UTILS_BIN_ROOT || exit /b

echo;Updating terminal font for `contools--utils`...
echo;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

rem Update console record for the 32-bit `callf.exe` and 64-bit `callf64.exe`
for /F "tokens=* delims="eol^= %%i in ("%CONTOOLS_UTILS_BIN_ROOT%/contools/callf.exe") do set "CMD_TERMINAL_CALLF_HKEY=%%~fi"
for /F "tokens=* delims="eol^= %%i in ("%CONTOOLS_UTILS_BIN_ROOT%/contools/callf64.exe") do set "CMD_TERMINAL_CALLF64_HKEY=%%~fi"

rem cleanup invalid hkey characters
set "CMD_TERMINAL_CALLF_HKEY=%CMD_TERMINAL_CALLF_HKEY:\=_%"
set "CMD_TERMINAL_CALLF64_HKEY=%CMD_TERMINAL_CALLF64_HKEY:\=_%"

rem encode characters for the `-u` flag
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!CMD_TERMINAL_CALLF_HKEY:%%=%%25!") do endlocal & set "CMD_TERMINAL_CALLF_HKEY=%%i"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!CMD_TERMINAL_CALLF64_HKEY:%%=%%25!") do endlocal & set "CMD_TERMINAL_CALLF64_HKEY=%%i"

if %WINDOWS_X64_VER%0 NEQ 0 (
  for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
    "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param_per_line -param "FaceName" -param "ScreenBufferSize" -u ^
    "HKCU\Console\%CMD_TERMINAL_CALLF_HKEY%" ^
    "HKCU\Console\%CMD_TERMINAL_CALLF64_HKEY%"`) do (
    set "PARAM_HKEY=%%i"
    set "PARAM_NAME=%%j"
    set "PARAM_VALUE=%%k"
    call "%%~dp0_install.update_console_registry.bat" || exit /b
  )
) else for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param_per_line -param "FaceName" -param "ScreenBufferSize" -u ^
  "HKCU\Console\%CMD_TERMINAL_CALLF_HKEY%"`) do (
  set "PARAM_HKEY=%%i"
  set "PARAM_NAME=%%j"
  set "PARAM_VALUE=%%k"
  call "%%~dp0_install.update_console_registry.bat" || exit /b
)

echo;

exit /b 0
