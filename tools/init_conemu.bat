@echo off

if %COMSPEC_X64_VER%0 NEQ 0 (
  set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD64_CMDLINE_ATTACH_PREFIX%
  set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD64_CMDLINE_RUN_PREFIX%
) else (
  set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD32_CMDLINE_ATTACH_PREFIX%
  set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD32_CMDLINE_RUN_PREFIX%
)

exit /b 0
