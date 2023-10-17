@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=0"
set "DETECTED_NPP_PYTHONSCRIPT_PYTHON_LIB="

echo.Searching Notepad++ PythonScript plugin installation...

call :DETECT %%*

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN% NEQ 0 (
  echo. * NPP_PYTHONSCRIPT_PLUGIN="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
  echo. * NPP_PYTHONSCRIPT_PYTHON_LIB="%DETECTED_NPP_PYTHONSCRIPT_PYTHON_LIB%"
) else (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
  set "DETECTED_NPP_PYTHONSCRIPT_PYTHON_LIB=%DETECTED_NPP_PYTHONSCRIPT_PYTHON_LIB%"
)

exit /b 0

:DETECT
rem drop last error level
type nul >nul

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already detected before continue.
  exit /b 255
) >&2

:DETECTED_NPP_EDITOR_OK

if exist "\\?\%DETECTED_NPP_ROOT%\plugins\PythonScript\PythonScript.dll" set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=1"

if exist "\\?\%DETECTED_NPP_ROOT%\plugins\PythonScript\lib\*" set "DETECTED_NPP_PYTHONSCRIPT_PYTHON_LIB=%DETECTED_NPP_ROOT%\plugins\PythonScript\lib"

exit /b 0
