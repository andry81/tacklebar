@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=0"

echo.Searching Notepad++ PythonScript plugin installation...

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already detected before continue.
  exit /b 255
) >&2

:DETECTED_NPP_EDITOR_OK

if exist "\\?\%DETECTED_NPP_ROOT%\plugins\PythonScript\PythonScript.dll" ^
if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\" set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=1"

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN% NEQ 0 (
  echo. * DETECTED_NPP_PYTHONSCRIPT_PLUGIN="%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
) else (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN%"
  if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN% NEQ 0 exit /b 0
  exit /b 1
)
