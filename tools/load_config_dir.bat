@echo off

setlocal

rem Description:
rem   Wrapper to load configuration files directory with `tacklebar`
rem   configuration files using `load_config_dir.bat` script.
rem   Overrides configuration files generator to customize the generation
rem   phase.

set "__?~dp0=%~dp0"
set "__?~n0=%~n0"
set "__?~nx0=%~nx0"

call "%%__?~dp0%%.load_config_dir/load_config_dir.read_flags.bat" %%* || exit /b

if %__?FLAG_SHIFT% GTR 0 for /L %%i in (1,1,%__?FLAG_SHIFT%) do shift

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

if %__?GEN_USER_CONFIG% EQU 0 goto GEN_USER_CONFIG_END

rem explicitly generate `config.<N>.vars`
set CONFIG_INDEX=0

:LOAD_CONFIG_LOOP
if not exist "%%~1/config.%CONFIG_INDEX%.vars.in" goto GEN_USER_CONFIG_END
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/gen_config.bat" -if_notexist -- %%1 %%2 "config.%%CONFIG_INDEX%%.vars" || exit /b
set /A CONFIG_INDEX+=1
goto LOAD_CONFIG_LOOP

:GEN_USER_CONFIG_END

rem CAUTION: no execution after this line
endlocal & "%CONTOOLS_BUILD_TOOLS_ROOT%/load_config_dir.bat"%__?BARE_FLAGS% -- %1 %2 "%EXPAND_PARAM0%" "%EXPAND_PARAM1%"
