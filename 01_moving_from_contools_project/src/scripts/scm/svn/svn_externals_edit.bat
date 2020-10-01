@echo off

svn pe svn:externals %*

echo.Waiting 10 sec or press any key...
timeout /t 10 > nul
