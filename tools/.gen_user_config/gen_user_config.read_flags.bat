@echo off

rem script flags
set FLAG_SHIFT=0
set "FLAG_CONEMU_ROOT="
set "FLAG_NPP_EDITOR="
set "FLAG_WINMERGE_ROOT="
set FLAG_ARAXIS_COMPARE_ENABLE=0
set "FLAG_ARAXIS_MERGE_ROOT="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-conemu_root" (
    set "FLAG_CONEMU_ROOT=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-npp_editor" (
    set "FLAG_NPP_EDITOR=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-winmerge_root" (
    set "FLAG_WINMERGE_ROOT=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-enable_araxis_compare" (
    set "FLAG_ARAXIS_COMPARE_ENABLE=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else if "%FLAG%" == "-araxis_merge_root" (
    set "FLAG_ARAXIS_MERGE_ROOT=%~2"
    shift
    set /A FLAG_SHIFT+=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  goto FLAGS_LOOP
)

exit /b 0
