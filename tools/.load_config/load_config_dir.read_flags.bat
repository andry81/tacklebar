@echo off

rem script flags
set __?FLAG_SHIFT=0
set __?FLAG_FLAGS_SCOPE=0
set __?GEN_SYSTEM_CONFIG=0
set __?GEN_USER_CONFIG=0
set "__?BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "__?FLAG=%~1"

if defined __?FLAG ^
if not "%__?FLAG:~0,1%" == "-" set "__?FLAG="

if defined __?FLAG if "%__?FLAG%" == "-+" set /A __?FLAG_FLAGS_SCOPE+=1
if defined __?FLAG if "%__?FLAG%" == "--" set /A __?FLAG_FLAGS_SCOPE-=1

if defined __?FLAG (
  if "%__?FLAG%" == "-gen_system_config" (
    set __?GEN_SYSTEM_CONFIG=1
    set __?BARE_FLAGS=%__?BARE_FLAGS% -load_system_output_config
  ) else if "%__?FLAG%" == "-gen_user_config" (
    set __?GEN_USER_CONFIG=1
    set __?BARE_FLAGS=%__?BARE_FLAGS% -load_user_output_config
  ) else if not "%__?FLAG%" == "-+" if not "%__?FLAG%" == "--" (
    set __?BARE_FLAGS=%__?BARE_FLAGS% %__?FLAG%
  )

  shift
  set /A __?FLAG_SHIFT+=1

  rem read until no flags
  if not "%__?FLAG%" == "--" goto FLAGS_LOOP

  if %__?FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %__?FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: [%__?FLAG_FLAGS_SCOPE%]: %__?FLAG%
  exit /b -255
) >&2

exit /b 0
