@echo off

if defined TACKLEBAR_PROJECT_ROOT_INIT0_DIR exit /b 0

call "%%~dp0__init__\__init__.bat" || exit /b

exit /b 0
