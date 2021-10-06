@echo off

if defined TACKLEBAR_PROJECT_ROOT_INIT0_DIR if exist "%TACKLEBAR_PROJECT_ROOT_INIT0_DIR%\" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat"
