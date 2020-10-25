@echo off

set LASTERRORLEVEL=0

rem init script search logic
for %%i in ("%~dp0..\..") do (
  for %%j in ("__init__.bat" "__init__\__init__.bat") do (
    call :INCLUDE %%i %%j && (
      setlocal ENABLEDELAYEDEXPANSION & for %%i in (!LASTERRORLEVEL!) do (
        endlocal
        set "LASTERRORLEVEL="
        exit /b %%i
      )
    )
  )
)

set "LASTERRORLEVEL="

exit /b 255

:INCLUDE
call :HAS_RECURSION "%%~1\%%~2" && exit /b 1
if not exist "%~1\%~2" exit /b 1
call "%%~1\%%~2"
set LASTERRORLEVEL=%ERRORLEVEL%
exit /b 0

:HAS_RECURSION
if /i "%~f1" == "%~f0" exit /b 0
exit /b 1
