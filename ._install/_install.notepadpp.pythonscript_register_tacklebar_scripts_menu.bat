@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" TEMP USERPROFILE TACKLEBAR_PROJECT_ROOT CONTOOLS_XMLSTARLET_ROOT || exit /b

echo.Searching for Notepad++ PythonScript plugin files...
echo.

if not defined DETECTED_NPP_EDITOR (
  echo.%?~nx0%: error: Notepad++ installation is not detected.
  echo.
  exit /b 255
) >&2

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN%0 EQU 0 (
  echo.%?~nx0%: error: Notepad++ PythonScript plugin installation is not detected.
  echo.
  exit /b 255
) >&2

if not exist "\\?\%USERPROFILE%\Application Data\Notepad++\*" (
  echo.%?~nx0%: error: Notepad++ user configuration directory is not found: "%USERPROFILE%\Application Data\Notepad++"
  echo.
  exit /b 255
) >&2

echo.Updating Notepad++ PythonScript plugin Tacklebar scripts menu...
echo.

echo.  * "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml"
echo.

if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf" (
  rem insert records into `PythonScriptStartup.cnf` file
  for /F "usebackq tokens=* delims="eol^= %%i in ("%TACKLEBAR_PROJECT_ROOT%/deploy/notepad++/plugins/PythonScript/Config/PythonScriptStartup.items.cnf") do (
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
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.items.cnf "%%USERPROFILE%%/Application Data/Notepad++/plugins/Config" /Y /D /H
)

echo.Registering Notepad++ PythonScript plugin Tacklebar scripts menu shortcuts...
echo.

echo.  * "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml"
echo.

if not exist "\\?\%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" (
  echo.%?~nx0%: error: Notepad++ shortcuts configuration file is not found: "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml"
  echo.
  exit /b 255
) >&2

rem defaults
set SHORTCUT_PLUGIN_INTERNALID=7
set SHORTCUT_PYTHONSCRIPT_UNDOALL_MENU_ID=0
set SHORTCUT_PYTHONSCRIPT_REDOALL_MENU_ID=0

rem calculate PythonScript menu ID for a menu item to use for `internalID` field

for /F "usebackq tokens=* delims="eol^= %%i in ("%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf") do set "LINE=%%i" & call :READ_PYTHONSCRIPT_CONFIG_LINE

goto READ_PYTHONSCRIPT_CONFIG_LINE_END

:READ_PYTHONSCRIPT_CONFIG_LINE
if "%LINE%" == "ITEM/\tacklebar\scripts\undo_all_files.py" set "SHORTCUT_PYTHONSCRIPT_UNDOALL_MENU_ID=%SHORTCUT_PLUGIN_INTERNALID%"
if "%LINE%" == "ITEM/\tacklebar\scripts\redo_all_files.py" set "SHORTCUT_PYTHONSCRIPT_REDOALL_MENU_ID=%SHORTCUT_PLUGIN_INTERNALID%"

if "%LINE:~0,5%" == "ITEM/" set /A SHORTCUT_PLUGIN_INTERNALID+=1

exit /b 0

:READ_PYTHONSCRIPT_CONFIG_LINE_END

set SHORTCUT_CTRL_ALT_Z_ASSIGNED=0
set SHORTCUT_CTRL_ALT_Y_ASSIGNED=0
set SHORTCUT_PYTHONSCRIPT_UNDOALL_ASSIGNED=0
set SHORTCUT_PYTHONSCRIPT_REDOALL_ASSIGNED=0

rem check existing records in `shortcuts.xml` file

rem CAUTION:
rem   1. If a variable is empty, then it would not be expanded in the `cmd.exe`
rem      command line or in the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement.
rem   2. The `cmd.exe` command line or the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement does expand twice.
rem
rem   We must expand the command line into a variable to avoid these above.
rem
set ?.="%CONTOOLS_XMLSTARLET_ROOT:/=\%\xml.exe" sel ^
  -t -m "/NotepadPlus/InternalCommands/Shortcut" -v "concat('Shortcut|', @id, '|', @Key, '|', @Ctrl, '|', @Alt, '|', @Shift)" -n ^
  -t -m "/NotepadPlus/Macros/Macro" -v "concat('Macro|', @Key, '|', @Ctrl, '|', @Alt, '|', @Shift, '|', @name)" -n ^
  -t -m "/NotepadPlus/UserDefinedCommands/Command" -v "concat('Command|', @Key, '|', @Ctrl, '|', @Alt, '|', @Shift, '|', @name)" -n ^
  -t -m "/NotepadPlus/PluginCommands/PluginCommand" -v "concat('PluginCommand|', @moduleName, '|', @internalID, '|', @Key, '|', @Ctrl, '|', @Alt, '|', @Shift)" -n ^
  -t -m "/NotepadPlus/ScintillaKeys/ScintKey" -v "concat('ScintKey|', @ScintID, '|', @moduleName, '|', @menuCmdID, '|', @Key, '|', @Ctrl, '|', @Alt, '|', @Shift)" -n ^
  "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml"

for /F "usebackq tokens=1,* delims=|"eol^= %%i in (`%%?.%%`) do (
  set "SHORTCUT_COMMAND_TYPE=%%i"
  set "SHORTCUT_INTERNALID=0"

  if "%%i" == "Shortcut" (
    for /F "tokens=1,2,3,4,5 delims=|"eol^= %%k in ("%%j") do (
      set "SHORTCUT_INTERNALID=%%k"
      set "SHORTCUT_KEY=%%l"
      set "SHORTCUT_KEY_CTRL=%%m"
      set "SHORTCUT_KEY_ALT=%%n"
      set "SHORTCUT_KEY_SHIFT=%%o"
      call :PROCESS_SHORTCUT_COMMAND
    )
  ) else if "%%i" == "Macro" (
    for /F "tokens=1,2,3,4,* delims=|"eol^= %%k in ("%%j") do (
      set "SHORTCUT_KEY=%%k"
      set "SHORTCUT_KEY_CTRL=%%l"
      set "SHORTCUT_KEY_ALT=%%m"
      set "SHORTCUT_KEY_SHIFT=%%n"
      call :PROCESS_SHORTCUT_COMMAND
    )
  ) else if "%%i" == "Command" (
    for /F "tokens=1,2,3,4,* delims=|"eol^= %%k in ("%%j") do (
      set "SHORTCUT_KEY=%%k"
      set "SHORTCUT_KEY_CTRL=%%l"
      set "SHORTCUT_KEY_ALT=%%m"
      set "SHORTCUT_KEY_SHIFT=%%n"
      call :PROCESS_SHORTCUT_COMMAND
    )
  ) else if "%%i" == "PluginCommand" (
    for /F "tokens=1,2,3,4,5,6 delims=|"eol^= %%k in ("%%j") do (
      set "PLUGIN_MODULE_NAME=%%k"
      set "SHORTCUT_INTERNALID=%%l"
      set "SHORTCUT_KEY=%%m"
      set "SHORTCUT_KEY_CTRL=%%n"
      set "SHORTCUT_KEY_ALT=%%o"
      set "SHORTCUT_KEY_SHIFT=%%p"
      call :PROCESS_SHORTCUT_COMMAND
    )
  ) else if "%%i" == "ScintKey" (
    for /F "tokens=1,2,3,4,5,6,7 delims=|"eol^= %%k in ("%%j") do (
      set "SHORTCUT_INTERNALID=%%k"
      set "SHORTCUT_KEY=%%n"
      set "SHORTCUT_KEY_CTRL=%%o"
      set "SHORTCUT_KEY_ALT=%%p"
      set "SHORTCUT_KEY_SHIFT=%%q"
      call :PROCESS_SHORTCUT_COMMAND
    )
  )
)

goto PROCESS_SHORTCUT_COMMAND_END

:PROCESS_SHORTCUT_COMMAND
if "%SHORTCUT_COMMAND_TYPE%" == "PluginCommand" if /i "%PLUGIN_MODULE_NAME%" == "PythonScript.dll" (
  if %SHORTCUT_PYTHONSCRIPT_UNDOALL_MENU_ID% EQU %SHORTCUT_INTERNALID% (
    set SHORTCUT_PYTHONSCRIPT_UNDOALL_ASSIGNED=1

    rem CTRL+ALT+Z, if-AND-else
    ( if "%SHORTCUT_KEY%" == "90" ( call; ) else type 2>nul ) && (
      if /i "%SHORTCUT_KEY_CTRL%" == "yes" ( call; ) else type 2>nul ) && (
      if /i "%SHORTCUT_KEY_ALT%" == "yes" ( call; ) else type 2>nul ) && (
      if /i not "%SHORTCUT_KEY_SHIFT%" == "yes" ( call; ) else type 2>nul ) && (
      echo.    =PluginCommand^|PythonScript.dll^|undo_all_files.py^|CTRL+ALT+Z
      call;
    ) || (
      echo.%?~nx0%: warning: `undo_all_files.py` menu item shortcut is assigned to a different key combination: key=%SHORTCUT_KEY%, ctrl=%SHORTCUT_KEY_CTRL%, alt=%SHORTCUT_KEY_ALT%, shift=%SHORTCUT_KEY_SHIFT%
      echo.
    ) >&2
  ) else if %SHORTCUT_PYTHONSCRIPT_REDOALL_MENU_ID% EQU %SHORTCUT_INTERNALID% (
    set SHORTCUT_PYTHONSCRIPT_REDOALL_ASSIGNED=1

    rem CTRL+ALT+Y, if-AND-else
    ( if "%SHORTCUT_KEY%" == "89" ( call; ) else type 2>nul ) && (
      if /i "%SHORTCUT_KEY_CTRL%" == "yes" ( call; ) else type 2>nul ) && (
      if /i "%SHORTCUT_KEY_ALT%" == "yes" ( call; ) else type 2>nul ) && (
      if /i not "%SHORTCUT_KEY_SHIFT%" == "yes" ( call; ) else type 2>nul ) && (
      echo.    =PluginCommand^|PythonScript.dll^|redo_all_files.py^|CTRL+ALT+Y
      call;
    ) || (
      echo.%?~nx0%: warning: `redo_all_files.py` menu item shortcut is assigned to a different key combination: key=%SHORTCUT_KEY%, ctrl=%SHORTCUT_KEY_CTRL%, alt=%SHORTCUT_KEY_ALT%, shift=%SHORTCUT_KEY_SHIFT%
      echo.
    ) >&2
  )
)

rem CTRL+ALT+Z
if "%SHORTCUT_KEY%" == "90" (
  if /i "%SHORTCUT_KEY_CTRL%" == "yes" if /i "%SHORTCUT_KEY_ALT%" == "yes" if /i not "%SHORTCUT_KEY_SHIFT%" == "yes" (
    set SHORTCUT_CTRL_ALT_Z_ASSIGNED=1

    rem if-AND-else
    ( if "%SHORTCUT_COMMAND_TYPE%" == "PluginCommand" ( call; ) else type 2>nul ) && (
      if /i "%PLUGIN_MODULE_NAME%" == "PythonScript.dll" ( call; ) else type 2>nul ) && (
      if %SHORTCUT_PYTHONSCRIPT_UNDOALL_MENU_ID% EQU %SHORTCUT_INTERNALID% ( call; ) else type 2>nul ) || (
      echo.%?~nx0%: warning: `CTRL+ALT+Z` shortcut key combination is assigned to a different command: command_type=`%SHORTCUT_COMMAND_TYPE%`, internalID=`%SHORTCUT_INTERNALID%`
      echo.
    ) >&2
  )
) else if "%SHORTCUT_KEY%" == "89" (
  if /i "%SHORTCUT_KEY_CTRL%" == "yes" if /i "%SHORTCUT_KEY_ALT%" == "yes" if /i not "%SHORTCUT_KEY_SHIFT%" == "yes" (
    set SHORTCUT_CTRL_ALT_Y_ASSIGNED=1

    rem if-AND-else
    ( if "%SHORTCUT_COMMAND_TYPE%" == "PluginCommand" ( call; ) else type 2>nul ) && (
      if /i "%PLUGIN_MODULE_NAME%" == "PythonScript.dll" ( call; ) else type 2>nul ) && (
      if %SHORTCUT_PYTHONSCRIPT_REDOALL_MENU_ID% EQU %SHORTCUT_INTERNALID% ( call; ) else type 2>nul ) || (
      echo.%?~nx0%: warning: `CTRL+ALT+Y` shortcut key combination is assigned to a different command: command_type=`%SHORTCUT_COMMAND_TYPE%`, internalID=`%SHORTCUT_INTERNALID%`
      echo.
    ) >&2
  )
)

exit /b 0

:PROCESS_SHORTCUT_COMMAND_END

rem backup before assign

if not exist "\\?\%USERPROFILE%\Application Data\Notepad++\backup\*" mkdir "%USERPROFILE%\Application Data\Notepad++\backup"

set "RANDOM_SUFFIX=%RANDOM%-%RANDOM%"

copy /Y /B "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" "%USERPROFILE%\Application Data\Notepad++\backup\shortcuts-%RANDOM_SUFFIX%.xml" >nul

rem assign shortcut key combination to menu item by inserting record into `shortcuts.xml` file

set "TEMP_DIR=%TEMP%\%?~n0%-%RANDOM_SUFFIX%"
set "OUTPUT_FILE=%TEMP_DIR%\shortcuts.xml.out"

mkdir "%TEMP_DIR%"
pushd "%TEMP_DIR%" || exit /b 255

set REFORMAT_LF_TO_CRLF=0

rem Sed line retuns match order: Windows -> Linux -> MacOS:  /^[^\r\n]*\r\n/ -> /^[^\r\n]*\n/ -> /^[^\r\n]*\r/
if %SHORTCUT_CTRL_ALT_Y_ASSIGNED% EQU 0 if %SHORTCUT_PYTHONSCRIPT_REDOALL_ASSIGNED% EQU 0 (
  echo.    +PluginCommand^|PythonScript.dll^|redo_all_files.py^|CTRL+ALT+Y

  (
    rem TODO: avoid xmlstarlet reformat to Linux line endings
    "%CONTOOLS_XMLSTARLET_ROOT%/xml.exe" ed -P ^
      --subnode "/NotepadPlus/PluginCommands" -t elem -n "PluginCommand" ^
      --var new_node "$prev" ^
      -a "$new_node" -t attr -n moduleName -v "PythonScript.dll" ^
      -a "$new_node" -t attr -n internalID -v "%SHORTCUT_PYTHONSCRIPT_REDOALL_MENU_ID%" ^
      -a "$new_node" -t attr -n Ctrl -v "yes" ^
      -a "$new_node" -t attr -n Alt -v "yes" ^
      -a "$new_node" -t attr -n Shift -v "no" ^
      -a "$new_node" -t attr -n Key -v "89" ^
      -i "$new_node" -t text -n "" -v "{{LR}}        " ^
    "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" > "%OUTPUT_FILE%"
  ) && (
    copy /Y /B "%OUTPUT_FILE%" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" >nul
    set REFORMAT_LF_TO_CRLF=1
  )
)

if %SHORTCUT_CTRL_ALT_Z_ASSIGNED% EQU 0 if %SHORTCUT_PYTHONSCRIPT_UNDOALL_ASSIGNED% EQU 0 (
  echo.    +PluginCommand^|PythonScript.dll^|undo_all_files.py^|CTRL+ALT+Z

  (
    rem TODO: avoid xmlstarlet reformat to Linux line endings
    "%CONTOOLS_XMLSTARLET_ROOT%/xml.exe" ed -P ^
      --subnode "/NotepadPlus/PluginCommands" -t elem -n "PluginCommand" ^
      --var new_node "$prev" ^
      -a "$new_node" -t attr -n moduleName -v "PythonScript.dll" ^
      -a "$new_node" -t attr -n internalID -v "%SHORTCUT_PYTHONSCRIPT_UNDOALL_MENU_ID%" ^
      -a "$new_node" -t attr -n Ctrl -v "yes" ^
      -a "$new_node" -t attr -n Alt -v "yes" ^
      -a "$new_node" -t attr -n Shift -v "no" ^
      -a "$new_node" -t attr -n Key -v "90" ^
      -i "$new_node" -t text -n "" -v "{{LR}}        " ^
    "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" > "%OUTPUT_FILE%"
  ) && (
    copy /Y /B "%OUTPUT_FILE%" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" >nul
    set REFORMAT_LF_TO_CRLF=1
  )
)

if %REFORMAT_LF_TO_CRLF% NEQ 0 (
  rem reformat if first inserted
  (
    "%CONTOOLS_GNUWIN32_ROOT%/bin/sed.exe" -r -b -e "s|/></PluginCommands>|/>{{LR}}    </PluginCommands>|mg" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" > "%OUTPUT_FILE%"
  ) && (
    copy /Y /B "%OUTPUT_FILE%" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" >nul
  )

  (
    rem xmlstarlet format issue workaround
    "%CONTOOLS_GNUWIN32_ROOT%/bin/sed.exe" -r -b -e "s|^\s*\{\{LR}}||mg" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" > "%OUTPUT_FILE%"
  ) && (
    copy /Y /B "%OUTPUT_FILE%" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" >nul
  )

  (
    "%CONTOOLS_GNUWIN32_ROOT%/bin/sed.exe" -r -b -e ":a; N; $!ba; /^[^\r\n]*\r\n/{s/\{\{LR}}/\r\n/mg;q;}; /^[^\r\n]*\n/{s/\{\{LR}}/\n/mg;q;}; /^[^\r\n]*\r/{s/\{\{LR}}/\r/mg;q;}" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" > "%OUTPUT_FILE%"
  ) && (
    copy /Y /B "%OUTPUT_FILE%" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml" >nul
  )

  rem TODO: avoid sed inplace reformat to Windows line endings
  rem WORKAROUND: reformat to Windows line ending using sed empty pattern
  "%CONTOOLS_GNUWIN32_ROOT%/bin/sed.exe" -b -i -e ":a/.*/ba" "%USERPROFILE%\Application Data\Notepad++\shortcuts.xml"
)

popd

rmdir /S /Q "%TEMP_DIR%"

echo.

exit /b 0
