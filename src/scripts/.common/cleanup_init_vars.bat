@echo off

setlocal

if exist "%INIT_VARS_FILE%" pushd "%PROJECT_LOG_DIR%" && (
  call "%%~dp0cleanup_file.bat" "%%INIT_VARS_FILE%%"

  rem delete GnuWin32 sed inplace backups
  del /F /Q "sed*" 2> nul

  popd
)
