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

set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT=0"

echo.Searching Notepad++ PythonScript plugin tacklebar extension installation...

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already detected before continue.
  exit /b 255
) >&2

:DETECTED_NPP_EDITOR_OK

if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\tacklebar\libs\npplib.py" ^
if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\startup.py" (
  "%SystemRoot%\System32\findstr.exe" /L /C:"/npplib.py" "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\startup.py" >nul && goto DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT_OK
)

rem return variable
(
  endlocal
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT%"
)

exit /b 1

:DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT_OK
set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT=1"

rem return variable
(
  endlocal
  set "DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT=%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT%"
)

exit /b 0
