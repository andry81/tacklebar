@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_ALLOW_RESUBST=0
set FLAG_REFRESH_BUTTONBAR_SUBST_MENU=0
set "REFRESH_BUTTONBAR_SUBST_MENU_BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-allow-resubst" (
    set FLAG_ALLOW_RESUBST=1
    set REFRESH_BUTTONBAR_SUBST_MENU_BARE_FLAGS=%REFRESH_BUTTONBAR_SUBST_MENU_BARE_FLAGS% %FLAG%
  ) else if "%FLAG%" == "-refresh-buttonbar-subst-menu" (
    set FLAG_REFRESH_BUTTONBAR_SUBST_MENU=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

set "DRIVE=%~1"
set "SUBST_PATH=%~2"

if not defined DRIVE (
  echo.%?~nx0%: error: drive is not defined.
  exit /b 255
) >&2

set "DRIVE=%DRIVE:~0,1%"

if not defined SUBST_PATH (
  echo.%?~nx0%: error: subst path is empty.
  exit /b 255
) >&2

for /F "eol= tokens=* delims=" %%i in ("%SUBST_PATH%\.") do set "SUBST_PATH_DRIVE=%%~di" & set "SUBST_PATH=%%~fi"

set "SUBST_PATH_DRIVE=%SUBST_PATH_DRIVE:~0,1%"

if /i "%DRIVE%" == "%SUBST_PATH_DRIVE%" (
  echo.%?~nx0%: error: subst drive must be to a path with different drive: %DRIVE%: =^> "%SUBST_PATH%".
  exit /b 255
) >&2

if not exist "%SUBST_PATH%\*" (
  echo.%?~nx0%: error: subst path does not exist: "%SUBST_PATH%".
  exit /b 255
) >&2

rem reread subst list

set FOR_BREAK=0

for /F "usebackq eol= tokens=1,* delims=>" %%i in (`@subst`) do (
  set "SUBSTED_DRIVE=%%i"
  set "SUBSTED_PATH=%%j"
  call :CHECK_DRIVE || exit /b
  call "%%CONTOOLS_ROOT%%/std/if_" %%FOR_BREAK%% NEQ 0 && goto SUBST_DRIVE
)

:SUBST_DRIVE
call :CMD subst %%DRIVE%%: "%%SUBST_PATH%%" || exit /b

if %FLAG_REFRESH_BUTTONBAR_SUBST_MENU% EQU 0 exit /b 0

rem refresh drives menu

echo.

call "%%?~dp0%%.refresh_buttonbar_subst_menu\_impl.refresh_buttonbar_subst_menu.bat"%%REFRESH_BUTTONBAR_SUBST_MENU_BARE_FLAGS%% .
exit /b

:CHECK_DRIVE
set "SUBSTED_DRIVE=%SUBSTED_DRIVE:~0,1%"
set "SUBSTED_PATH=%SUBSTED_PATH:~1%"

if /i "%SUBSTED_DRIVE%" == "%DRIVE%" (
  if %FLAG_ALLOW_RESUBST% EQU 0 (
    echo.%?~nx0%: error: drive already substed: %SUBSTED_DRIVE%: =^> "%SUBSTED_PATH%".
    exit /b 254
  ) >&2 else (
    set FOR_BREAK=1
    call :CMD subst /d %%DRIVE%%:
  )
)

exit /b

:CMD
echo.^>%*
(%*)
