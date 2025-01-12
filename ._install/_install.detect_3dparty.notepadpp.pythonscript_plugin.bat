@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=0"
set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT="
set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL="
set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER=0"

echo.Searching `Notepad++` `PythonScript` plugin installation...
echo.

call :DETECT %%*

echo. * NPP_PYTHONSCRIPT_PLUGIN="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
echo. * NPP_PYTHONSCRIPT_PLUGIN_ROOT="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%"
echo. * NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL%"
echo. * NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER%"

echo.

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN% EQU 0 (
  echo.%?~nx0%: warning: `Notepad++` `PythonScript` plugin is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%"
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL%"
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: `Notepad++` must be already detected before continue.
  exit /b 255
) >&2

:DETECTED_NPP_EDITOR_OK

set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT=%DETECTED_NPP_ROOT%\plugins\PythonScript"
set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\PythonScript.dll"

if exist "\\?\%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL%" set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=1"

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN% EQU 0 exit /b 0

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER=1"

exit /b 0
