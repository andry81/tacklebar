@echo off

setlocal

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

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
    echo;%?~%: error: invalid flag: %FLAG%
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

set "MOUNTVOL_RECORD_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mountvol_records.lst"
set "MOUNTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mounted_drives.lst"

set "BUTTONBAR_FILE_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\buttonbar"
set "BUTTONBAR_CLEAR_DRIVE_CACHE_FILE_NAME=clear_drive_cache.bar"

set "TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_TMP=%BUTTONBAR_FILE_DIR_TMP%\%BUTTONBAR_CLEAR_DRIVE_CACHE_FILE_NAME%"
set "TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN_TMP=%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_TMP%.in"

set "TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN=%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN:/=\%"
set "TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU=%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU:/=\%"

mkdir "%BUTTONBAR_FILE_DIR_TMP%"

rem read volume mount list

set "MOUNTVOL_RECORD_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mountvol_records.lst"
set "MOUNTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mounted_drives.lst"

"%SystemRoot%\System32\mountvol.exe" | "%SystemRoot%\System32\findstr.exe" /R /C:"^[\t ][ \t]*[A-Z]:\\\\" > "%MOUNTVOL_RECORD_LIST_FILE_TMP%"

type nul > "%MOUNTED_DRIVE_LIST_FILE_TMP%"

(for /F "usebackq tokens=* delims=	 "eol^= %%i in ("%MOUNTVOL_RECORD_LIST_FILE_TMP%") do set "MOUNTVOL_RECORD_LINE=%%i" & call :PARSE_MOUNTVOL_RECORD) >> "%MOUNTED_DRIVE_LIST_FILE_TMP%"

goto PARSE_MOUNTVOL_RECORD_END

:PARSE_MOUNTVOL_RECORD
for /F "tokens=* delims="eol^= %%i in ("%MOUNTVOL_RECORD_LINE:~0,1%") do echo;%%i
exit /b 0

:PARSE_MOUNTVOL_RECORD_END

"%SystemRoot%\System32\sort.exe" "%MOUNTED_DRIVE_LIST_FILE_TMP%" /O "%MOUNTED_DRIVE_LIST_FILE_TMP%"

rem generate subst button bar menu from input template

copy /Y /B "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN%" "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN_TMP%" >nul 2>nul

set BUTTONCOUNT=2
set INDEX=0

(
  for /F "usebackq tokens=* delims=	 "eol^= %%i in ("%MOUNTED_DRIVE_LIST_FILE_TMP%") do (
    set "CLEAR_DRIVE_CACHE_MENU_ITEM=%%i"
    set /A BUTTONCOUNT+=1
    call :GEN_CLEAR_DRIVE_CACHE_BUTTONBAR
    set /A INDEX+=1
  )
) >> "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN_TMP%"

goto GEN_CLEAR_DRIVE_CACHE_BUTTONBAR_END

:GEN_CLEAR_DRIVE_CACHE_BUTTONBAR
set "DRIVE=%CLEAR_DRIVE_CACHE_MENU_ITEM:~0,1%"

echo;button%BUTTONCOUNT%=%%COMMANDER_SCRIPTS_ROOT%%\tacklebar\res\images\cleanup\clear_drive_cache.ico
echo;cmd%BUTTONCOUNT%=em_tkl_clear_drive_cache %DRIVE%
echo;menu%BUTTONCOUNT%=Clear cache: %DRIVE%

echo;

exit /b 0

:GEN_CLEAR_DRIVE_CACHE_BUTTONBAR_END

if %INDEX% EQU 0 set /A BUTTONCOUNT+=1
if %INDEX% EQU 0 (
  echo;button%BUTTONCOUNT%=
  echo;menu%BUTTONCOUNT%=Clear cache: ^<empty^>
  echo;
) >> "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_IN_TMP%"

rem update `Buttoncount` key

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/gen_config.bat" ^
  -r "{{BUTTON_COUNT}}" "%%BUTTONCOUNT%%" ^
  "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_CLEAR_DRIVE_CACHE_FILE_NAME%%"

copy /Y /B "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU_TMP%" "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU%" >nul 2>nul

rem remove subst button bar cache file to reload menu

del /F /Q /A:-D "%TACKLEBAR_BUTTONBAR_CLEAR_DRIVE_CACHE_MENU%.br2" 2>nul

exit /b 0
