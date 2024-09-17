@echo off

rem Description:
rem   Script task (loop) to xcopy log directory if writable.

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" CONTOOLS_ROOT PROJECT_LOG_FILE PROJECT_LOG_DIR || exit /b

rem CAUTION:
rem   The console window is hidden and any attempt to write into it will close the script.
rem   So we must suppress any output here.
rem
(
  call "%%CONTOOLS_ROOT%%/locks/wait_dir_files_write_access.bat" "%%PROJECT_LOG_DIR%%" && (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%PROJECT_LOG_DIR%%" "%%INSTALL_TO_DIR%%\tacklebar\.log\%%PROJECT_LOG_DIR_NAME%%" /E /Y /D
    exit /b
  )
) >nul 2>nul
