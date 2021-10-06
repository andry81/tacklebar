@echo off

setlocal

set "CALLF_BARE_FLAGS="
rem if %FLAG_USE_X64% NEQ 0 set "CALLF_BARE_FLAGS= /disable-wow64-fs-redir"

if %USE_MINTTY%0 NEQ 0 (
  %MINTTY_TERMINAL_PREFIX% -e "%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
    /ret-child-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
    /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
    "${COMSPEC}" "/i /c \"@\"${?~f0}\" {*}\"" %* || exit /b
  exit /b 0
)
if %USE_CONEMU%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
if %USE_CONEMU%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
  %CONEMU_CMDLINE_RUN_PREFIX% "%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
    /ret-child-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
    /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
    "${COMSPEC}" "/i /c \"@\"${?~f0}\" {@}\"" -cur_console:n %* || exit /b
  exit /b 0
)
"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
  /ret-child-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
  /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
  "${COMSPEC}" "/i /c \"@\"${?~f0}\" {*}\"" %* || exit /b
exit /b 0
