@echo off

setlocal

call "%%~dp0../../._install/script_init.bat" tacklebar install-totalcmd-configs %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

exit /b %LAST_ERROR%

:MAIN
rem where to install
call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" INSTALL_TO_DIR "%%COMMANDER_SCRIPTS_ROOT%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/._install/_install.detect.totalcmd.bat" || exit /b
call "%%TACKLEBAR_PROJECT_ROOT%%/._install/_install.totalcmd.tacklebar_config.bat" || exit /b

exit /b 0
