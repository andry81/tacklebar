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

set "DETECTED_WINMERGE_COMPARE_TOOL="

echo.Searching WinMerge installation...

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2 delims=|" %%i in (`@"%SystemRoot%\System32\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param "Executable" ^
  "HKCU\SOFTWARE\Thingamahoochie\WinMerge" "HKCU\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge" ^
  "HKLM\SOFTWARE\Thingamahoochie\WinMerge" "HKLM\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge"`) do (
  set "INSTALL_FILE=%%j"
  call :FIND_INSTALL_FILE INSTALL_FILE && goto INSTALL_FILE_END
)

goto INSTALL_FILE_END

:FIND_INSTALL_FILE
if not "%~1" == "" if not defined %~1 ( shift & goto FIND_INSTALL_FILE )

call set "VALUE=%%%~1:"=%%"
shift

if "%VALUE%" == "." set "VALUE="

if defined VALUE if exist "%VALUE%" ( set "REGQUERY_VALUE=%VALUE%" & exit /b 0 )

if not "%~1" == "" goto FIND_INSTALL_FILE

exit /b 1

:INSTALL_FILE_END

if not defined REGQUERY_VALUE goto END_SEARCH_WINMERGE_COMPARE_TOOL

call :CANONICAL_PATH DETECTED_WINMERGE_COMPARE_TOOL "%%REGQUERY_VALUE%%"

:END_SEARCH_WINMERGE_COMPARE_TOOL
if defined DETECTED_WINMERGE_COMPARE_TOOL if not exist "%DETECTED_WINMERGE_COMPARE_TOOL%" set "DETECTED_WINMERGE_COMPARE_TOOL="
if defined DETECTED_WINMERGE_COMPARE_TOOL (
  echo. * WINMERGE_COMPARE_TOOL="%DETECTED_WINMERGE_COMPARE_TOOL%"
) else (
  echo.%?~nx0%: warning: WinMerge is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_WINMERGE_COMPARE_TOOL=%DETECTED_WINMERGE_COMPARE_TOOL%"
)

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
