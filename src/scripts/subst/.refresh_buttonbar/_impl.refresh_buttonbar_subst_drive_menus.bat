@echo off

setlocal

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_ALLOW_RESUBST=0
set FLAG_REFRESH_BUTTONBAR_SUBST_DRIVE_MENUS=0
set "DRIVE_BARE_FLAGS="

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
    set DRIVE_BARE_FLAGS=%DRIVE_BARE_FLAGS% %FLAG%
  ) else if "%FLAG%" == "-refresh-buttonbar-subst-drive-menus" (
    set FLAG_REFRESH_BUTTONBAR_SUBST_DRIVE_MENUS=1
    set DRIVE_BARE_FLAGS=%DRIVE_BARE_FLAGS% %FLAG%
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

set "ALL_DRIVES_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\all_drives.lst"
set "MOUNTVOL_RECORD_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mountvol_records.lst"
set "SUBST_RECORD_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\subst_records.lst"
set "MOUNTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mounted_drives.lst"
set "SUBSTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\substed_drives.lst"
set "SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\substed_drive_menu_item.lst"
set "NOT_MOUNTED_DRIVE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\not_mounted_drives.lst"
set "SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\subst_drive_menu_item.lst"

set "BUTTONBAR_FILE_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\buttonbar"
set "BUTTONBAR_SUBST_DRIVE_FILE_NAME=subst_drive.bar"
set "BUTTONBAR_UNSUBST_DRIVE_FILE_NAME=unsubst_drive.bar"

set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP=%BUTTONBAR_FILE_DIR_TMP%\%BUTTONBAR_SUBST_DRIVE_FILE_NAME%"
set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP%.in"
set "TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_TMP=%BUTTONBAR_FILE_DIR_TMP%\%BUTTONBAR_UNSUBST_DRIVE_FILE_NAME%"
set "TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN_TMP=%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_TMP%.in"

set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN:/=\%"
set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU:/=\%"
set "TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN=%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN:/=\%"
set "TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU=%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU:/=\%"

call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%BUTTONBAR_FILE_DIR_TMP%%"

"%SystemRoot%\System32\mountvol.exe" | "%SystemRoot%\System32\findstr.exe" /R /C:"^[\t ][ \t]*[A-Z]:\\\\" > "%MOUNTVOL_RECORD_LIST_FILE_TMP%"

"%SystemRoot%\System32\subst.exe" >> "%SUBST_RECORD_LIST_FILE_TMP%"

type nul > "%SUBSTED_DRIVE_LIST_FILE_TMP%"
type nul > "%SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP%"

(
  for /F "usebackq eol= tokens=* delims=" %%i in ("%SUBST_RECORD_LIST_FILE_TMP%") do (
    set "SUBST_RECORD_LINE=%%i"
    call :PARSE_SUBST_RECORD
  )
) >> "%SUBSTED_DRIVE_LIST_FILE_TMP%"

goto PARSE_SUBST_RECORD_END

:PARSE_SUBST_RECORD
for /F "eol= tokens=1,* delims=>" %%i in ("%SUBST_RECORD_LINE%") do (
  set "SUBSTED_DRIVE=%%i"
  set "SUBSTED_PATH=%%j"
  call :PARSE_SUBST_RECORDS
)
exit /b 0

:PARSE_SUBST_RECORDS
set "SUBSTED_DRIVE=%SUBSTED_DRIVE:~0,1%"
set "SUBSTED_PATH=%SUBSTED_PATH:~1%"

echo.%SUBSTED_DRIVE%

if defined SUBSTED_PATH (
  setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("%SUBSTED_PATH%") do endlocal & echo.%SUBSTED_DRIVE% ^(%%i^)
) >> "%SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP%" else (
  echo.%SUBSTED_DRIVE%
) >> "%SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP%"

exit /b 0

:PARSE_SUBST_RECORD_END

rem add subst drives if `-allow-resubst` is NOT defined

if %FLAG_ALLOW_RESUBST% EQU 0 type "%SUBST_RECORD_LIST_FILE_TMP%" >> "%MOUNTVOL_RECORD_LIST_FILE_TMP%"

rem prepare subst drive list

type nul > "%MOUNTED_DRIVE_LIST_FILE_TMP%"

(
  for /F "usebackq eol= tokens=* delims=	 " %%i in ("%MOUNTVOL_RECORD_LIST_FILE_TMP%") do (
    set "MOUNTVOL_RECORD_LINE=%%i"
    call :PARSE_MOUNTVOL_RECORD
  )
) >> "%MOUNTED_DRIVE_LIST_FILE_TMP%"

goto PARSE_MOUNTVOL_RECORD_END

:PARSE_MOUNTVOL_RECORD
for /F "eol= tokens=* delims=" %%i in ("%MOUNTVOL_RECORD_LINE:~0,1%") do echo.%%i
exit /b 0

:PARSE_MOUNTVOL_RECORD_END

"%SystemRoot%\System32\sort.exe" "%MOUNTED_DRIVE_LIST_FILE_TMP%" /O "%MOUNTED_DRIVE_LIST_FILE_TMP%"

rem generate subst drive list from not subst drive list

(
  for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do echo.%%i
) > "%ALL_DRIVES_LIST_FILE_TMP%"

rem CAUTION:
rem   `findstr.exe` returns error and empty output if the exclusion list in the `/G` parameter is empty.
rem

"%SystemRoot%\System32\findstr.exe" /B /L /I /V /G:"%MOUNTED_DRIVE_LIST_FILE_TMP%" "%ALL_DRIVES_LIST_FILE_TMP%" > "%NOT_MOUNTED_DRIVE_LIST_FILE_TMP%" || ^
type "%ALL_DRIVES_LIST_FILE_TMP%" > "%NOT_MOUNTED_DRIVE_LIST_FILE_TMP%"

rem add to substed drives the subst path

"%SystemRoot%\System32\findstr.exe" /B /L /I /V /G:"%SUBSTED_DRIVE_LIST_FILE_TMP%" "%NOT_MOUNTED_DRIVE_LIST_FILE_TMP%" > "%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%" 2>nul || ^
type "%NOT_MOUNTED_DRIVE_LIST_FILE_TMP%" > "%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%"

if %FLAG_ALLOW_RESUBST% NEQ 0 type "%SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP%" >> "%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%"

"%SystemRoot%\System32\sort.exe" "%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%" /O "%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%"

rem generate subst button bar menu from input template

copy /Y /B "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN%" "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%" >nul 2>nul

set BUTTONCOUNT=2
set INDEX=0

(
  for /F "usebackq eol= tokens=* delims=	 " %%i in ("%SUBST_DRIVE_MENU_ITEM_LIST_FILE_TMP%") do (
    set "SUBST_DRIVE_MENU_ITEM=%%i"
    set /A BUTTONCOUNT+=1
    call :GEN_SUBST_DRIVE_BUTTONBAR
    set /A INDEX+=1
  )
) >> "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%"

goto GEN_SUBST_DRIVE_BUTTONBAR_END

:GEN_SUBST_DRIVE_BUTTONBAR
set "DRIVE=%SUBST_DRIVE_MENU_ITEM:~0,1%"

echo.button%BUTTONCOUNT%=%%COMMANDER_SCRIPTS_ROOT%%\tacklebar\res\images\subst\subst_drive.ico
echo.cmd%BUTTONCOUNT%=em_tkl_subst_drive_by_current_dir %DRIVE%%DRIVE_BARE_FLAGS%

setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("%SUBST_DRIVE_MENU_ITEM%") do ^
endlocal & echo.menu%BUTTONCOUNT%=Subst: %%i

echo.

exit /b 0

:GEN_SUBST_DRIVE_BUTTONBAR_END

if %INDEX% EQU 0 set /A BUTTONCOUNT+=1
if %INDEX% EQU 0 (
  echo.button%BUTTONCOUNT%=
  echo.menu%BUTTONCOUNT%=Subst: ^<empty^>
  echo.
) >> "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%"

rem update `Buttoncount` key

call "%%CONTOOLS_ROOT%%/build/gen_config.bat" ^
  -r "{{BUTTON_COUNT}}" "%%BUTTONCOUNT%%" ^
  "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_SUBST_DRIVE_FILE_NAME%%"

copy /Y /B "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP%" "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU%" >nul 2>nul

rem remove subst button bar cache file to reload menu

del /F /Q "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU%.br2" 2>nul

rem generate unsubst button bar menu from input template

copy /Y /B "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN%" "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN_TMP%" >nul 2>nul

set BUTTONCOUNT=2
set INDEX=0

(
  for /F "usebackq eol= tokens=* delims=	 " %%i in ("%SUBSTED_DRIVE_MENU_ITEM_LIST_FILE_TMP%") do (
    set "UNSUBST_DRIVE_MENU_ITEM=%%i"
    set /A BUTTONCOUNT+=1
    call :GEN_UNSUBST_DRIVE_BUTTONBAR
    set /A INDEX+=1
  )
) >> "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN_TMP%"

goto GEN_UNSUBST_DRIVE_BUTTONBAR_END

:GEN_UNSUBST_DRIVE_BUTTONBAR
set "DRIVE=%UNSUBST_DRIVE_MENU_ITEM:~0,1%"

echo.button%BUTTONCOUNT%=%%COMMANDER_SCRIPTS_ROOT%%\tacklebar\res\images\subst\unsubst_drive.ico
echo.cmd%BUTTONCOUNT%=em_tkl_unsubst_drive %DRIVE%%DRIVE_BARE_FLAGS%

setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("%UNSUBST_DRIVE_MENU_ITEM%") do ^
endlocal & echo.menu%BUTTONCOUNT%=Unsubst: %%i

echo.

exit /b 0

:GEN_UNSUBST_DRIVE_BUTTONBAR_END

if %INDEX% EQU 0 set /A BUTTONCOUNT+=1
if %INDEX% EQU 0 (
  echo.button%BUTTONCOUNT%=
  echo.menu%BUTTONCOUNT%=Unsubst: ^<empty^>
  echo.
) >> "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_IN_TMP%"

rem update `Buttoncount` key

call "%%CONTOOLS_ROOT%%/build/gen_config.bat" ^
  -r "{{BUTTON_COUNT}}" "%%BUTTONCOUNT%%" ^
  "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_UNSUBST_DRIVE_FILE_NAME%%"

copy /Y /B "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU_TMP%" "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU%" >nul 2>nul

rem remove unsubst button bar cache file to reload menu

del /F /Q "%TACKLEBAR_BUTTONBAR_UNSUBST_DRIVE_MENU%.br2" 2>nul

exit /b 0

:CMD
echo.^>%*
(%*)
