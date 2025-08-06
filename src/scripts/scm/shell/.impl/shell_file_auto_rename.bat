@echo off

setlocal

set NAME_INDEX=0

:COMPARE_LOOP
for /F "tokens=* delims="eol^= %%i in ("\\?\%FROM_FILE_PATH%") do for /F "tokens=* delims="eol^= %%j in ("\\?\%TO_FILE_PATH%") do if %%~zi EQU %%~zj (
  if not "%%~zi%%~zj" == "00" (
    if not exist "%FROM_FILE_PATH%" set "FROM_FILE_PATH=%%~si"
    if not exist "%TO_FILE_PATH%" set "TO_FILE_PATH=%%~sj"
    "%SystemRoot%\System32\fc.exe" /B "%FROM_FILE_PATH%" "%TO_FILE_PATH%" >nul 2>nul && (
      echo;%?~%: warning: TO_FILE_PATH file has equal content, skipped:
      echo;  FROM_FILE_PATH="%FROM_FILE_PATH%"
      echo;  TO_FILE_PATH  ="%TO_FILE_PATH%"
      exit /b 1
    ) >&2
  ) else (
    echo;%?~%: warning: TO_FILE_PATH file has equal content, skipped:
    echo;  FROM_FILE_PATH="%FROM_FILE_PATH%"
    echo;  TO_FILE_PATH  ="%TO_FILE_PATH%"
    exit /b 1
  ) >&2
)

:RENAME_LOOP
set /A NAME_INDEX+=1

for /F "tokens=* delims="eol^= %%i in ("%TO_FILE_NAME%") do set "TO_FILE_RENAMED=%%~ni (%NAME_INDEX%)%%~xi"

set "TO_FILE_PATH=%TO_FILE_DIR%\%TO_FILE_RENAMED%"

if exist "\\?\%TO_FILE_PATH%" if not exist "\\?\%TO_FILE_PATH%\*" ( goto COMPARE_LOOP ) else goto RENAME_LOOP

rem CAUTION:
rem   The `%%~fi` or `%%~nxi` expansions here goes change a path characters case to the case of the existed file path.
rem
rem WORKAROUND:
rem   We must encode a path to a nonexistent path and after conversion to an absolute path, decode it back and so bypass case change in a path characters.
rem
for /F "tokens=* delims="eol^= %%i in ("%TO_FILE_PATH%%FILE_NAME_TEMP_SUFFIX%\.") do ^
for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TO_FILE_PATH=%%~fi" & set "TO_FILE_DIR=%%~fj" & set "TO_FILE_NAME=%%~nxi"

rem decode paths back
call set "TO_FILE_PATH=%%TO_FILE_PATH:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "TO_FILE_NAME=%%TO_FILE_NAME:%FILE_NAME_TEMP_SUFFIX%=%%"

(
  endlocal
  set "TO_FILE_PATH=%TO_FILE_PATH%"
  set "TO_FILE_NAME=%TO_FILE_NAME%"
  exit /b 0
)
