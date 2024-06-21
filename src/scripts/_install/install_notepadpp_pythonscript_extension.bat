@echo off

setlocal

call "%%~dp0../../._install/script_init.bat" tacklebar install-notepadpp-pythonscript_extension %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

exit /b %LAST_ERROR%

:MAIN
call "%%TACKLEBAR_PROJECT_ROOT%%/._install/_install.detect_3dparty.notepadpp.bat" || exit /b
call "%%TACKLEBAR_PROJECT_ROOT%%/._install/_install.detect_3dparty.notepadpp.pythonscript_plugin.bat" || exit /b
call "%%TACKLEBAR_PROJECT_ROOT%%/._install/_install.notepadpp.pythonscript_extension.bat" || exit /b

exit /b 0
