@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set "FLAG_CHCP="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else (
    echo.%?~%: error: invalid flag: %FLAG%
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
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

rem read volume mount list

set "MOUNTVOL_RECORD_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mountvol_records.lst"
set "MOUNTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mounted_drives.lst"

"%SystemRoot%\System32\mountvol.exe" | "%SystemRoot%\System32\findstr.exe" /R /C:"^[\t ][ \t]*[A-Z]:\\\\" > "%MOUNTVOL_RECORD_LIST_FILE_TMP%"

type nul > "%MOUNTED_DRIVE_LIST_FILE_TMP%"

(for /F "usebackq tokens=* delims=	 "eol^= %%i in ("%MOUNTVOL_RECORD_LIST_FILE_TMP%") do set "MOUNTVOL_RECORD_LINE=%%i" & call :PARSE_MOUNTVOL_RECORD) >> "%MOUNTED_DRIVE_LIST_FILE_TMP%"

goto PARSE_MOUNTVOL_RECORD_END

:PARSE_MOUNTVOL_RECORD
for /F "tokens=* delims="eol^= %%i in ("%MOUNTVOL_RECORD_LINE:~0,1%") do echo.%%i
exit /b 0

:PARSE_MOUNTVOL_RECORD_END

"%SystemRoot%\System32\sort.exe" "%MOUNTED_DRIVE_LIST_FILE_TMP%" /O "%MOUNTED_DRIVE_LIST_FILE_TMP%"

set "CLEAR_CACHE_CMDLINE="

for /F "usebackq tokens=* delims="eol^= %%i in ("%MOUNTED_DRIVE_LIST_FILE_TMP%") do (
  set "MOUNTED_DRIVE=%%i"
  call set CLEAR_CACHE_CMDLINE=%%CLEAR_CACHE_CMDLINE%% %%MOUNTED_DRIVE%%:
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_UTILS_BIN_ROOT%%/contools/clearcache.exe"%%CLEAR_CACHE_CMDLINE%% || exit /b
exit /b 0
