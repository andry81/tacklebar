@echo off

rem Description:
rem   Script task (loop) to xcopy log directory if writable.

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" CONTOOLS_ROOT PROJECT_LOG_FILE PROJECT_LOG_DIR || exit /b

:WAIT_LOOP

rem Check log directory write access.
rem Based on:
rem   https://stackoverflow.com/questions/1999988/how-to-check-whether-a-file-dir-is-writable-in-batch-scripts/59884789#59884789
rem
rem CAUTION:
rem   The console window is hidden and any attempt to write into it will close the script.
rem   So we must suppress any output here.
rem
(
  move /Y "%PROJECT_LOG_DIR%\*" "%PROJECT_LOG_DIR%" && (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%PROJECT_LOG_DIR%%" "%%INSTALL_TO_DIR%%\tacklebar\.log\%%PROJECT_LOG_DIR_NAME%%" /E /Y /D
    exit /b
  )

  call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
) >nul 2>nul

goto WAIT_LOOP
