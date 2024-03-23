@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%?~dp0%%_install.detect.tacklebar.bat"
call "%%?~dp0%%_install.detect.totalcmd.bat"
call "%%?~dp0%%_install.detect_3dparty.conemu.bat"
call "%%?~dp0%%_install.detect_3dparty.cygwin.bat"
call "%%?~dp0%%_install.detect_3dparty.msys.bat"
call "%%?~dp0%%_install.detect_3dparty.mintty.bat"
call "%%?~dp0%%_install.detect_3dparty.notepadpp.bat"
call "%%?~dp0%%_install.detect_3dparty.notepadpp.pythonscript_plugin.bat"
call "%%?~dp0%%_install.detect_3dparty.winmerge.bat"
call "%%?~dp0%%_install.detect_3dparty.araxismerge.bat"
call "%%?~dp0%%_install.detect_3dparty.git_shell_root.bat"
call "%%?~dp0%%_install.detect_3dparty.gitextensions.bat"

rem return all `DETECTED_*` variables
for /F "usebackq eol= tokens=1,* delims==" %%i in (`@set DETECTED_ 2^>nul`) do endlocal & set "%%i=%%j"
