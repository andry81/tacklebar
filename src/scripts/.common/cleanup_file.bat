@echo off

setlocal

set "CLEANUP_FILE=%~1"

rem CAUTION:
rem   The `sed` does reformat the line returns.
rem

rem * remove all custom tokens (ppk_XXXXXXXXXXXXXXXX) (password private key)
rem * remove all GitHub tokens (ghp_XXXXXXXXXXXXXXXX)
"%CONTOOLS_GNUWIN32_ROOT%/bin/sed.exe" -E -i ^
  "s/ppk_[0-9a-zA-Z]{16,}/ppk_*/g; s/ghp_[0-9a-zA-Z]{16,}/ghp_*/g" ^
  "%CLEANUP_FILE%"
