@echo off

setlocal

set "?09=/"
if %USE_MINTTY%0 NEQ 0 if %USE_MINTTY_ROOT_AS_MSYS_ROOT%0 NEQ 0 set "?09=//"

rem script flags
set FLAG_MSYS_TERMINAL=0
set "CALLF_BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-msys" (
    set FLAG_MSYS_TERMINAL=1
    set "?09=//"
  ) else if "%FLAG%" == "-log-stdin" (
    set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% %?09%tee-stdin "%PROJECT_LOG_FILE%" %?09%pipe-stdin-to-child-stdin
  ) else if "%FLAG%" == "-log-conout" (
    set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% %?09%tee-stdout "%PROJECT_LOG_FILE%" %?09%tee-stderr-dup 1
  ) else goto FLAGS_LOOP_END

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

:FLAGS_LOOP_END

call :MAIN %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
exit /b

:MAIN
rem variables escaping

if %FLAG_USE_X64%0 NEQ 0 set CALLF_BARE_FLAGS= %CALLF_BARE_FLAGS% %?09%disable-wow64-fs-redir

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

set "?~f0=%?~f0:{=\{%"
set "COMSPECLNK=%COMSPECLNK:{=\{%"

(
  endlocal

  if %USE_MINTTY%0 NEQ 0 (
    %MINTTY_TERMINAL_PREFIX% -e "%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
      /load-parent-proc-init-env-vars ^
      %?09%attach-parent-console %?09%ret-child-exit %?09%no-expand-env %?09%no-subst-pos-vars ^
      %?09%v IMPL_MODE 1 %?09%v INIT_VARS_FILE "%INIT_VARS_FILE%" ^
      %?09%ra "%%" "%%?01%%" %?09%v "?01" "%%" ^
      "%COMSPECLNK%" "%?09%c \"@\"%?~f0%\" {*}\"" %* || exit /b
    exit /b 0
  )

  if %USE_CONEMU%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
  if %USE_CONEMU%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
    %CONEMU_CMDLINE_RUN_PREFIX% "%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
      /load-parent-proc-init-env-vars ^
      /attach-parent-console /ret-child-exit /no-expand-env /no-subst-pos-vars ^
      /v IMPL_MODE 1 /v INIT_VARS_FILE "%INIT_VARS_FILE%" ^
      /ra "%%" "%%?01%%" /v "?01" "%%" ^
      "%COMSPECLNK%" "/c \"@\"%?~f0%\" {@}\"" -cur_console:n %* || exit /b
    exit /b 0
  )

  "%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
    /load-parent-proc-init-env-vars ^
    /attach-parent-console /ret-child-exit /no-expand-env /no-subst-pos-vars ^
    /v IMPL_MODE 1 /v INIT_VARS_FILE "%INIT_VARS_FILE%" ^
    /ra "%%" "%%?01%%" /v "?01" "%%" ^
    "%COMSPECLNK%" "/c \"@\"%?~f0%\" {*}\"" %* || exit /b
  exit /b 0
)
