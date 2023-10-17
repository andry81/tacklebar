@echo off

echo.Reading properties...

for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%\.") do ( set "FILE_PATH=%%~fi" & set "FILE_NAME=%%~nxi" )

set /A PROPS_FILTER_PATH_INDEX=0
if exist "\\?\%FILE_PATH%\*" goto EDIT_DIR_PATH

if %PROPS_FILTER_PATH_INDEX% GEQ %PROPS_FILTER_FILE_INDEX% (
  echo.%?~nx0%: warning: no properties selected for the path: "%FILE_PATH%"
  exit /b 0
) >&2

:EDIT_FILE_PATH_LOOP

set "PATH_INDEX_STR=%PATH_INDEX%"
if %PATH_INDEX% LSS 100 set "PATH_INDEX_STR=0%PATH_INDEX_STR%"
if %PATH_INDEX% LSS 10 set "PATH_INDEX_STR=0%PATH_INDEX_STR%"

set "PROPS_INOUT_PATH_DIR=%PROPS_INOUT_FILES_DIR%\%PATH_INDEX_STR%\%FILE_NAME%"
call set "PROP_NAME=%%PROPS_FILTER[file][%PROPS_FILTER_PATH_INDEX%]%%"
set "PROP_NAME_DECORATED=%PROP_NAME::=--%"

(
  type nul>nul
  if %PROPS_FILTER_PATH_INDEX% EQU 0 (
    echo.^>mkdir "%PROPS_INOUT_PATH_DIR%"
    mkdir "%PROPS_INOUT_PATH_DIR%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%PROPS_INOUT_PATH_DIR%" >nul ) else type 2>nul || (
      echo.%?~nx0%: error: could not create a file directory: "%PROPS_INOUT_PATH_DIR%".
      exit /b 60
    ) >&2
  )
) && (
  if %FLAG_CREATE_PROP_IF_EMPTY% EQU 0 (
    svn pget "%PROP_NAME%" "%FILE_PATH%" --non-interactive 2>nul >"%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%"
  ) else (
    svn pget "%PROP_NAME%" "%FILE_PATH%" --non-interactive 2>nul >"%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%"
    type nul>nul
  )
) && (
  copy "%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%" "%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%.orig" /B /Y 2>&1 >nul
  for /F "eol= tokens=* delims=" %%i in ("%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%") do (echo.%%i) >> "%EDIT_LIST_FILE_TMP%"
  for /F "eol= tokens=* delims=" %%i in ("%PROP_NAME%|%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%|%FILE_PATH%") do (echo.%%i) >> "%CHANGESET_LIST_FILE_TMP%"
  set /A NUM_PATHS_TO_EDIT+=1
)

set /A PROPS_FILTER_PATH_INDEX+=1

if %PROPS_FILTER_PATH_INDEX% LSS %PROPS_FILTER_FILE_INDEX% goto EDIT_FILE_PATH_LOOP

exit /b 0

:EDIT_DIR_PATH
if %PROPS_FILTER_PATH_INDEX% GEQ %PROPS_FILTER_DIR_INDEX% (
  echo.%?~nx0%: warning: no properties selected for the path: "%FILE_PATH%"
  exit /b 0
) >&2

:EDIT_DIR_PATH_LOOP
set "PATH_INDEX_STR=%PATH_INDEX%"
if %PATH_INDEX% LSS 100 set "PATH_INDEX_STR=0%PATH_INDEX_STR%"
if %PATH_INDEX% LSS 10 set "PATH_INDEX_STR=0%PATH_INDEX_STR%"

set "PROPS_INOUT_PATH_DIR=%PROPS_INOUT_FILES_DIR%\%PATH_INDEX_STR%\%FILE_NAME%"
call set "PROP_NAME=%%PROPS_FILTER[dir][%PROPS_FILTER_PATH_INDEX%]%%"
set "PROP_NAME_DECORATED=%PROP_NAME::=--%"

(
  type nul>nul
  if %PROPS_FILTER_PATH_INDEX% EQU 0 (
    echo.^>mkdir "%PROPS_INOUT_PATH_DIR%"
    mkdir "%PROPS_INOUT_PATH_DIR%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%PROPS_INOUT_PATH_DIR%" >nul ) else type 2>nul || (
      echo.%?~nx0%: error: could not create a file directory: "%PROPS_INOUT_PATH_DIR%".
      exit /b 61
    ) >&2
  )
) && (
  if %FLAG_CREATE_PROP_IF_EMPTY% EQU 0 (
    svn pget "%PROP_NAME%" "%FILE_PATH%" --non-interactive 2>nul >"%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%"
  ) else (
    svn pget "%PROP_NAME%" "%FILE_PATH%" --non-interactive 2>nul >"%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%"
    type nul>nul
  )
) && (
  copy "%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%" "%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%.orig" /B /Y 2>&1 >nul
  for /F "eol= tokens=* delims=" %%i in ("%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%") do (echo.%%i) >> "%EDIT_LIST_FILE_TMP%"
  for /F "eol= tokens=* delims=" %%i in ("%PROP_NAME%|%PROPS_INOUT_PATH_DIR%\.%PROP_NAME_DECORATED%|%FILE_PATH%") do (echo.%%i) >> "%CHANGESET_LIST_FILE_TMP%"
  set /A NUM_PATHS_TO_EDIT+=1
)

set /A PROPS_FILTER_PATH_INDEX+=1

if %PROPS_FILTER_PATH_INDEX% LSS %PROPS_FILTER_DIR_INDEX% goto EDIT_DIR_PATH_LOOP

exit /b 0
