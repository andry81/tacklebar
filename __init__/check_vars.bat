@echo off

setlocal

rem CAUTION:
rem   The `declare_builtins.bat` script must be called before.

for %%i in (%*) do (
  if not defined %%~i (
    echo.%?~nx0%: error: `%%~i` variable is not defined.
    exit /b 255
  ) >&2
)

exit /b 0
