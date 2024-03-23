@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

rem call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
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

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "FILES_LIST="
set NUM_FILES=0

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

rem read selected file names into variable
:ARG_FILTER_LOOP
if "%~1" == "" goto ARG_FILTER_LOOP_END
rem ignore a sub directory open, files in a sub directory must be selected explicitly in a panel!
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set FILES_LIST=%FILES_LIST% %1
set /A NUM_FILES+=1

shift

goto ARG_FILTER_LOOP

:ARG_FILTER_LOOP_END

if %NUM_FILES% EQU 0 exit /b 0

if %FLAG_WAIT_EXIT% NEQ 0 (
  if %FLAG_NOTEPADPLUSPLUS% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% %%FILES_LIST%%
  ) else (
    for %%i in (%FILES_LIST%) do (
      call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% %%i
    )
  )
) else (
  if %FLAG_NOTEPADPLUSPLUS% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% %%FILES_LIST%%
  ) else (
    for %%i in (%FILES_LIST%) do (
      call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% %%i
    )
  )
)

exit /b
