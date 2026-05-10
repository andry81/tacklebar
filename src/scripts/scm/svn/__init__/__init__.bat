@echo off

if defined TACKLEBAR_PROJECT_ROOT_INIT0_DIR if exist "%TACKLEBAR_PROJECT_ROOT_INIT0_DIR%\*" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat" || exit /b

rem retarget externals of an external project

call "%%CONTOOLS_ROOT%%/std/canonical_path_if_ndef.bat" SVNCMD_PROJECT_EXTERNALS_ROOT "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%"

rem disable code page change in nested __init__
set /A NO_CHCP+=1
call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/svncmd/__init__/__init__.bat" -no_load_user_config || exit /b
set /A NO_CHCP-=1

exit /b 0
