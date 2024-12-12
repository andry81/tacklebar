@echo off

set NUM_PATHS_WRITED=0

rem read edited property paths from list file
for /F "usebackq tokens=1,2,* delims=|"eol^= %%i in ("%CHANGESET_LIST_FILE_TMP%") do (
  set "PROP_NAME=%%i"
  set "PROP_VALUE_FILE=%%j"
  set "PROP_FILE_PATH=%%k"
  call :UPDATE_PROPS
)

exit /b

:UPDATE_PROPS
rem at first check if property file is blank or contains only white spaces and delete the property
call :PRINT_WO_LAST_EMPTY_LINES "%%PROP_VALUE_FILE%%" > "%SCRIPT_TEMP_CURRENT_DIR%\tmp\.%PROP_NAME_DECORATED%"
for /F %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\tmp\.%PROP_NAME_DECORATED%") do set "PROP_VALUE_FILE_SIZE=%%~zi"
if %PROP_VALUE_FILE_SIZE% GTR 0 goto PROP_IS_NOT_EMPTY

if %NUM_PATHS_WRITED% EQU 0 echo.Writing properties...

set /A NUM_PATHS_WRITED+=1
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" svn pdel "%%PROP_NAME%%" "%%PROP_FILE_PATH%%" --non-interactive || exit /b

exit /b 0

:PROP_IS_NOT_EMPTY
call :PRINT_WO_LAST_EMPTY_LINES "%%PROP_VALUE_FILE%%.orig" > "%SCRIPT_TEMP_CURRENT_DIR%\tmp\.%PROP_NAME_DECORATED%.orig"

rem compare ignoring empty lines
"%SystemRoot%\System32\fc.exe" "%PROP_VALUE_FILE:/=\%" "%PROP_VALUE_FILE%.orig" >nul && exit /b 0

if %NUM_PATHS_WRITED% EQU 0 echo.Writing properties...

set /A NUM_PATHS_WRITED+=1
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" svn pset "%%PROP_NAME%%" "%%PROP_FILE_PATH%%" -F "%%SCRIPT_TEMP_CURRENT_DIR%%\tmp\.%%PROP_NAME_DECORATED%%" --non-interactive || exit /b

exit /b 0

:PRINT_WO_LAST_EMPTY_LINES
setlocal DISABLEDELAYEDEXPANSION

set "FILE=%~1"

set NUM_RETURN_LINES=0
for /F "usebackq delims="eol^= %%i in (`@"%SystemRoot%\System32\findstr.exe" /B /N /R /C:".*" "%FILE%" 2^>nul`) do set "LINE_STR=%%i" & call :PRINT_LINES

exit /b 0

:PRINT_LINES
setlocal ENABLEDELAYEDEXPANSION
set OFFSET=0
:OFFSET_LOOP
set CHAR=!LINE_STR:~%OFFSET%,1!
if not "!CHAR!" == ":" ( set /A OFFSET+=1 && goto OFFSET_LOOP )
set /A OFFSET+=1
set "LINE_STR=!STR_PREFIX!!LINE_STR:~%OFFSET%!!STR_SUFFIX!"
if defined LINE_STR (
  if %NUM_RETURN_LINES% GTR 0 for /L %%i in (1,1,%NUM_RETURN_LINES%) do echo.
  set NUM_RETURN_LINES=0
  echo.!LINE_STR!
) else set /A NUM_RETURN_LINES+=1

(
  endlocal
  set "NUM_RETURN_LINES=%NUM_RETURN_LINES%"
  exit /b
)

exit /b 0

