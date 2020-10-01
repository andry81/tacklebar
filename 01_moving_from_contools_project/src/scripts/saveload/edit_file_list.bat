@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || goto :EOF

rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

if %FLAG_PAUSE_ON_EXIT% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-pause_on_exit" (
    set FLAG_PAUSE_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-pause_timeout_sec" (
    set "FLAG_PAUSE_TIMEOUT_SEC=%~2"
    shift
  ) else if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
  ) else if "%FLAG%" == "-npp" (
    set FLAG_NOTEPADPLUSPLUS=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: LIST_FILE_PATH is not defined.
  exit /b 1
) >&2

if not exist "%LIST_FILE_PATH%" (
  echo.%?~nx0%: error: LIST_FILE_PATH does not exist: "%LIST_FILE_PATH%".
  exit /b 2
) >&2

if exist "%LIST_FILE_PATH%\" (
  echo.%?~nx0%: error: LIST_FILE_PATH must be a file: "%LIST_FILE_PATH%".
  exit /b 3
) >&2

if %FLAG_NOTEPADPLUSPLUS% EQU 0 goto USE_BASIC_EDITOR

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
)

exit /b

:USE_BASIC_NOTEPAD
if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
)

exit /b

:CMD
echo.^>%*
(%*)
