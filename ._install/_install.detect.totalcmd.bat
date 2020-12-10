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

set "DETECTED_TOTALCMD_INSTALL_DIR="

echo.Searching Total Commander installation...

rem 64-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_CURRENT_USER\Software\Ghisler\Total Commander" InstallDir >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_CURRENT_USER\Software\Wow6432Node\Ghisler\Total Commander" InstallDir >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\Software\Ghisler\Total Commander" InstallDir >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Ghisler\Total Commander" InstallDir >nul 2>nul

if not defined REGQUERY_VALUE goto END_SEARCH_TOTALCMD_INSTALL_DIR

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH DETECTED_TOTALCMD_INSTALL_DIR "%%REGQUERY_VALUE%%"

:END_SEARCH_TOTALCMD_INSTALL_DIR
if defined DETECTED_TOTALCMD_INSTALL_DIR if not exist "%DETECTED_TOTALCMD_INSTALL_DIR%" set "DETECTED_TOTALCMD_INSTALL_DIR="
if defined DETECTED_TOTALCMD_INSTALL_DIR (
  echo. * TOTALCMD_INSTALL_DIR="%DETECTED_TOTALCMD_INSTALL_DIR%"
) else (
  echo.%?~nx0%: warning: Total Commander is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TOTALCMD_INSTALL_DIR=%DETECTED_TOTALCMD_INSTALL_DIR%"
)

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
