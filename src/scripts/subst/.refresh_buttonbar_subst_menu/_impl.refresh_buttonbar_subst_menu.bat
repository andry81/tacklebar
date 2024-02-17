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
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_ALLOW_RESUBST=0
set FLAG_REFRESH_BUTTONBAR_SUBST_MENU=0
set "SUBST_DRIVE_BARE_FLAGS="

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
    set SUBST_DRIVE_BARE_FLAGS=%SUBST_DRIVE_BARE_FLAGS% %FLAG%
  ) else if "%FLAG%" == "-refresh-buttonbar-subst-menu" (
    set FLAG_REFRESH_BUTTONBAR_SUBST_MENU=1
    set SUBST_DRIVE_BARE_FLAGS=%SUBST_DRIVE_BARE_FLAGS% %FLAG%
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
set "MOUNTVOL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\mountvol.lst"
set "NOT_SUBST_DRIVES_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\not_subst_drives.lst"
set "SUBST_DRIVES_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\subst_drives.lst"
set "BUTTONBAR_FILE_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\buttonbar"
set "BUTTONBAR_FILE_NAME=subst_drives.bar"
set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP=%BUTTONBAR_FILE_DIR_TMP%\%BUTTONBAR_FILE_NAME%"
set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP%.in"

set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN:/=\%"
set "TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU=%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU:/=\%"

"%SystemRoot%\System32\mountvol.exe" | "%SystemRoot%\System32\findstr.exe" /R /C:"^[\t ][ \t]*[A-Z]:\\\\" > "%MOUNTVOL_LIST_FILE_TMP%"

rem add subst drives if `-allow-resubst` is NOT defined
if %FLAG_ALLOW_RESUBST% EQU 0 "%SystemRoot%\System32\subst.exe" >> "%MOUNTVOL_LIST_FILE_TMP%"

rem prepare subst drive list

(
  for /F "usebackq eol= tokens=* delims=	 " %%i in ("%MOUNTVOL_LIST_FILE_TMP%") do (
    set "LINE=%%i"
    call :PARSE_MOUNTVOL_LINE
  )
) > "%NOT_SUBST_DRIVES_LIST_FILE_TMP%"

"%SystemRoot%\System32\sort.exe" "%NOT_SUBST_DRIVES_LIST_FILE_TMP%" /O "%NOT_SUBST_DRIVES_LIST_FILE_TMP%"

rem generate subst drive list from not subst drive list

(
  for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do echo.%%i
) > "%ALL_DRIVES_LIST_FILE_TMP%"

"%SystemRoot%\System32\findstr.exe" /B /L /I /V /G:"%NOT_SUBST_DRIVES_LIST_FILE_TMP%" "%ALL_DRIVES_LIST_FILE_TMP%" > "%SUBST_DRIVES_LIST_FILE_TMP%"

rem generate button bar menu from input template

set BUTTONCOUNT=2

call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%BUTTONBAR_FILE_DIR_TMP%%"

copy /Y /B "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN%" "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%" >nul 2>nul

set INDEX=0

(
  for /F "usebackq eol= tokens=* delims=	 " %%i in ("%SUBST_DRIVES_LIST_FILE_TMP%") do (
    set "DRIVE=%%i"
    set /A BUTTONCOUNT+=1
    call :GEN_SUBST_DRIVE_BUTTONBAR
    set /A INDEX+=1
  )
) >> "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%"

if %INDEX% EQU 0 set /A BUTTONCOUNT+=1
if %INDEX% EQU 0 (
  echo.button%BUTTONCOUNT%=
  echo.menu%BUTTONCOUNT%=Subst: ^<empty^>
  echo.
) >> "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_IN_TMP%"

rem update `Buttoncount` key

call "%%CONTOOLS_ROOT%%/build/gen_config.bat" ^
  -r "{{BUTTON_COUNT}}" "%%BUTTONCOUNT%%" ^
  "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_FILE_DIR_TMP%%" "%%BUTTONBAR_FILE_NAME%%"

copy /Y /B "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU_TMP%" "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU%" >nul 2>nul

rem remove button bar cache file to reload menu

del /F /Q "%TACKLEBAR_BUTTONBAR_SUBST_DRIVE_MENU%.br2" 2>nul

exit /b 0

:GEN_SUBST_DRIVE_BUTTONBAR
echo.button%BUTTONCOUNT%=%%COMMANDER_SCRIPTS_ROOT%%\tacklebar\res\images\subst\subst_drive.ico
echo.cmd%BUTTONCOUNT%=em_tkl_subst_drive_by_current_dir %DRIVE%%SUBST_DRIVE_BARE_FLAGS%
echo.menu%BUTTONCOUNT%=Subst: %DRIVE%
echo.
exit /b 0

:PARSE_MOUNTVOL_LINE
for /F "eol= tokens=* delims=" %%i in ("%LINE:~0,1%") do echo.%%i
exit /b 0

:CMD
echo.^>%*
(%*)
