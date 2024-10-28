@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

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
  if "%FLAG%" == "-wait" (
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
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

if %FLAG_WAIT_EXIT% NEQ 0 (
  if %FLAG_NOTEPADPLUSPLUS% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%%
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%%
  )
) else (
  if %FLAG_NOTEPADPLUSPLUS% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%%
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%%
  )
)

exit /b 0
