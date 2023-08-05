> :information_source: this log lists user most visible changes

> :warning: to find all changes use [changelog.txt](https://github.com/andry81/tacklebar/tree/HEAD/changelog.txt) file

> :information_source: Legend: :shield: - security; :wrench: - fixed; :new: - new; :pencil: - changed; :twisted_rightwards_arrows: - refactor

## 2023.06.11:
* :new: new: _install: copy `.externals` into installation directory to be able to identify external dependencies from the installation directory

## 2023.05.23:
* :pencil: changed: deploy/totalcmd/ButtonBars: `call.vbs` script replaced by `callf.exe` utility
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/saveload/load/load_saveload_list.bar: `LOADSEARCH` replaced by `em_saveload_prefix_bom_and_loadlist_from_utf8_bom_slot_*` macro functions
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/saveload/select/select_by_saveload_list.bar: `LOADSELECTION` replaced by `em_saveload_prefix_bom_and_loadselection_from_utf8_bom_slot_*` macro functions

## 2023.05.22:
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/link/*.bar: `call.vbs` script replaced by `callf.exe` utility

## 2023.05.10:
* :new: new: src/scripts/scm/shell/shell_move_by_list.bat: added config file generation and edit for script parameterization

## 2023.05.09:
* :pencil: changed: src/scripts/scm: merged shell/svn/git scripts into single, added `-use_svn` and `-use_git` flags to independently enable copy/move/rename including svn and git

## 2023.03.16:
* :new: new: src/scripts/scm/shell/shell_reset_links_in_dir.bat: added `-p[rint-assign]` flag to print all assignments
* :new: new: src/scripts/scm/shell/shell_reset_links_in_dir.bat: added `-reset-wd` flag as shorter version of `-reset-wd-from-target-path`
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/link/link.bar: added `-p` flag to all `shell_reset_links_in_dir.bat` script calls to print all assignments

## 2022.12.22:
* :wrench: fixed: src/scripts/scm/shell/shell_reset_links_in_dir.bat: added `-reset-wd-from-target-path` flag to reset `WorkingDirectory` property from `TargetPath` property (shortcut target must not be an existed directory path, otherwise `WorkingDirectory` must be not empty, otherwise - ignore)
* :new: new: deploy/totalcmd/ButtonBars/_common/link/link.bar: added usage of `shell_reset_links_in_dir.bat` with `-reset-wd-from-target-path` flag

## 2022.09.29:
* :new: new: _install.bat, deploy/totalcmd: added option to install a single button menu instead of multiple buttons menu

## 2022.08.12:
* :wrench: fixed: src/scripts/scm/shell/shell_reset_links_in_dir.bat: execution fixup in case of `)` characters in the path

## 2022.07.02:
* :wrench: fixed: deploy/totalcmd/Profile: profile cleanup and update
* :new: new: src/scripts/scm/shell: added `shell_reset_links_in_dir.bat` script to reset shortcut files in a directory
* :new: new: deploy/totalcmd/ButtonBars/_common/link/link.bar: shell reset shortcut files in current directory (recursively) item

## 2022.06.20:
* :wrench: fixed: src/scripts: potential `!` character truncation in path variables expansion

## 2022.03.14:
* :new: new: src/scripts/scm/shell: added `shell_mklink_by_list.bat` script to create shortcut files by list
* :new: new: deploy/totalcmd/ButtonBars/_common: mklink, _menu.bar: menu for `shell_mklink_by_list.bat` script
* :new: new: res/images/mklink: icons for `shell_mklink_by_list.bat` script

## 2022.01.11:
* :wrench: fixed: src/scripts/terminal: run_cmd.bat: interactive input processing for the arrow keys in the `cmd.exe`

## 2022.01.05:
* :pencil: changed: _install.bat: separately detect 32/64 bit mintty/msys/cygwin

## 2021.12.22:
* :wrench: fixed: src/scripts/.common: environment variables correct reset in case of mintty processes inheritance chain break (mintty terminal does retart itself with parent process immediate exit)
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/terminal: execute without or hide default cmd.exe terminal window in case of mintty terminal window usage

## 2021.10.06:
* :new: new: deploy: MinTTY shell terminal support as a standalone submenu (MinTTY button bars + icons)
## 2021.10.05:
* :new: new: src/scripts: `MINTTY*_ROOT`, `MINTTY*_TERMINAL_PREFIX`, `USE_MINTTY` variables to enable use mintty in scripts
* :new: new: src/scripts: `MSYS*_TERMINAL_PREFIX`, `CYGWIN*_TERMINAL_PREFIX` variables to use mintty terminal from msys/cygwin
* :pencil: changed: src/scripts: `CONEMU_ENABLE` variable is replaced by `USE_CONEMU` variable
* :pencil: changed: src/scripts: removed `-use_cmd` flag as `cmd.exe` is always used as terminal by default now

## 2021.10.04:
* :pencil: changed: completely replaced usage of `mtee.exe` utility by the `callf.exe` utility

## 2021.07.21:
* :pencil: changed: removed administrator privileges double elevation in install scripts
* :pencil: changed: replaced usage of `winshell_call.vbs` and `call.vbs` scripts by the `callf.exe` executable with less issues and better functionality

## 2021.05.05:
* :pencil: changed: Now is required to explicitly select the file list to save it into saveload slot, otherwise the empty list would be saved. Has meaning after the `Compare Panels` command (Shift-F2), where the cursor usually points a random file.

## 2021.04.10:
* :wrench: fixed: deploy/totalcmd: saveload: load/select from utf-8 files w/o BOM (`[TC9.51] LOADSEARCH/LOADSELECTION does not work over utf-8 file list w/o BOM` : https://www.ghisler.ch/board/viewtopic.php?t=74342 )

## 2021.03.12:
* :new: new: deploy/totalcmd/ButtonBars/_common/saveload/load, deploy/totalcmd/Profile: `LOADLIST` command usage (available in the Total Commander beginning from version 10b1).

## 2021.03.09:
* :wrench: fixed: src/scripts/scm: immediate exit if copy/move/rename list was not changed

## 2021.03.02:
* :wrench: fixed: src/scripts/terminal: run_cmd.bat: rewrited (merged with `run_msys.bat`/`run_cygwin.bat`) to fix console input history (up/down buttons) travel


> :information_source: the rest of the log is truncated

