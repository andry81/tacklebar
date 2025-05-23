@echo off

rem script flags
set FLAG_SKIP=0
set FLAG_SHIFT=0
set FLAG_ELEVATED=0
set FLAG_NO_LOG=0
set "FLAG_CHCP="
set FLAG_QUIT_ON_EXIT=0
set FLAG_USE_MINTTY=0
set FLAG_USE_CONEMU=0
set FLAG_USE_X64=0
set FLAG_USE_X32=0
set "EXEC_TERMINAL_PREFIX_BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

rem CAUTION:
rem   Below is a specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem

if defined FLAG (
  if "%FLAG%" == "-elevated" (
    set FLAG_ELEVATED=1
  ) else if "%FLAG%" == "-no_log" (
    set FLAG_NO_LOG=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-quit_on_exit" (
    set FLAG_QUIT_ON_EXIT=1
  ) else if "%FLAG%" == "-use_mintty" (
    set FLAG_USE_MINTTY=1
  ) else if "%FLAG%" == "-use_conemu" (
    set FLAG_USE_CONEMU=1
  ) else if "%FLAG%" == "-x64" (
    set FLAG_USE_X64=1
  ) else if "%FLAG%" == "-x32" (
    set FLAG_USE_X32=1
  ) else if "%FLAG%" == "-X" (
    set EXEC_TERMINAL_PREFIX_BARE_FLAGS=%EXEC_TERMINAL_PREFIX_BARE_FLAGS% -X %2
    shift
    set /A FLAG_SKIP=+2
    set /A FLAG_SHIFT+=1
  ) else (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  goto FLAGS_LOOP
)

exit /b 0
