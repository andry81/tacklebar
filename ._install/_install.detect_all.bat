@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

call "%%?~dp0%%_install.detect.tacklebar.bat"
call "%%?~dp0%%_install.detect.totalcmd.bat"
call "%%?~dp0%%_install.detect_3dparty.conemu.bat"
call "%%?~dp0%%_install.detect_3dparty.notepadpp.bat"
call "%%?~dp0%%_install.detect_3dparty.notepadpp.pythonscript_plugin.bat"
call "%%?~dp0%%_install.detect_3dparty.winmerge.bat"
call "%%?~dp0%%_install.detect_3dparty.araxismerge.bat"
call "%%?~dp0%%_install.detect_3dparty.git_shell_root.bat"
call "%%?~dp0%%_install.detect_3dparty.gitextensions.bat"
