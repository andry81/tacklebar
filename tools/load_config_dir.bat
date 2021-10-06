@echo off

setlocal

set "__?~dp0=%~dp0"
set "__?~n0=%~n0"
set "__?~nx0=%~nx0"

rem script flags
set __?GEN_SYSTEM_CONFIG=0
set __?GEN_USER_CONFIG=0
set "__?BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "__?FLAG=%~1"

if defined __?FLAG ^
if not "%__?FLAG:~0,1%" == "-" set "__?FLAG="

if defined __?FLAG (
  if "%__?FLAG%" == "-gen_system_config" (
    set __?GEN_SYSTEM_CONFIG=1
    set __?BARE_FLAGS=%__?BARE_FLAGS% -load_system_output_config
  ) else if "%__?FLAG%" == "-gen_user_config" (
    set __?GEN_USER_CONFIG=1
    set __?BARE_FLAGS=%__?BARE_FLAGS% -load_user_output_config
  ) else (
    set __?BARE_FLAGS=%__?BARE_FLAGS% %__?FLAG%
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "EXPAND_PARAM0="
if %WINDOWS_MAJOR_VER% EQU 5 set "EXPAND_PARAM0=OSWINXP"

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem
set "EXPAND_PARAM1=OS32"
if %COMSPEC_X64_VER%0 NEQ 0 set "EXPAND_PARAM1="

if %__?GEN_SYSTEM_CONFIG% NEQ 0 (
  rem explicitly generate `config.system.vars`
  call "%%TACKLEBAR_PROJECT_ROOT%%/tools/gen_system_config.bat" %%1 %%2 "config.system.vars" || exit /b
)

if %__?GEN_SYSTEM_CONFIG% EQU 0 goto GEN_USER_CONFIG_END

rem explicitly generate `config.<N>.vars`
set CONFIG_INDEX=0

:LOAD_CONFIG_LOOP
if not exist "%%~1/config.%CONFIG_INDEX%.vars.in" goto GEN_USER_CONFIG_END
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/gen_user_config.bat" %%1 %%2 "config.%%CONFIG_INDEX%%.vars" || exit /b
set /A CONFIG_INDEX+=1
goto LOAD_CONFIG_LOOP

:GEN_USER_CONFIG_END

(
  endlocal
  call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat"%__?BARE_FLAGS% -lite_parse %%1 %%2 "%EXPAND_PARAM0%" "%EXPAND_PARAM1%" || exit /b
  exit /b 0
)
