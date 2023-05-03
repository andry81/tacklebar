@echo off

setlocal

if exist "%PROJECT_LOG_FILE%" pushd "%PROJECT_LOG_DIR%" && (
  call "%%~dp0cleanup_file.bat" "%%PROJECT_LOG_FILE%%"

  rem delete GnuWin32 sed inplace backups
  del /F /Q "sed*" 2> nul

  popd
)
