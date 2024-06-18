@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" INSTALL_TO_DIR PROJECT_LOG_FILE_NAME_DATE_TIME || exit /b

echo.Searching for Notepad++ PythonScript plugin files...
echo.

if not exist "\\?\%USERPROFILE%\Application Data\Notepad++\*" (
  echo.%?~nx0%: error: Notepad++ user configuration directory is not found: "%USERPROFILE%/Application Data/Notepad++"
  echo.
  exit /b 255
) >&2

echo.Updating Notepad++ PythonScript plugin...
echo.

echo.  * "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"
echo.

if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf" (
  rem insert records into `PythonScriptStartup.cnf` file
  for /F "useback eol= tokens=* delims=" %%i in ("%TACKLEBAR_PROJECT_ROOT%/deploy/notepad++/plugins/PythonScript/Config/PythonScriptStartup.cnf") do (
    "%SystemRoot%\System32\findstr.exe" /B /E /L /C:"%%i" "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf" >nul && (
      echo.    =%%i
      call;
    ) || (
      echo.    +%%i
      (echo.%%i) >> "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"
    )
  )
  echo.
) else (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.cnf "%%USERPROFILE%%/Application Data/Notepad++/plugins/Config" /Y /D /H
)

echo.  * "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\"
echo.

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" || exit /b

if exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\startup.py" (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin startup script has been already existed, will be replaced.
  echo.
) >&2

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools--notepadplusplus/scripts/python/tacklebar" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%/tacklebar/scripts" /E /Y /D

setlocal

rem exclude all hidden files
set "XCOPY_EXCLUDE_FILES_LIST=:.*"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools--notepadplusplus/scripts/python" *.* "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" /Y /D /H
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools--notepadplusplus"                *.* "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%/tacklebar" /Y /D /H

endlocal

exit /b 0
