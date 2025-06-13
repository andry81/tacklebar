@echo off

setlocal

set /P "FILE_PATH="

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" TortoiseProc.exe %%COMMAND%% /path:"%%FILE_PATH%%" %%*
