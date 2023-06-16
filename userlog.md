> :information_source: this log lists user most visible changes

> :warning: to find all changes use [changelog.txt](https://github.com/andry81/tacklebar/tree/HEAD/changelog.txt) file

> :information_source: Legend: :shield: - security; :wrench: - fixed; :new: - new; :pencil: - changed; :twisted_rightwards_arrows: - refactor

## 2023.03.16:
* :pencil: changed: deploy/totalcmd/ButtonBars/_common/link/link.bar: added `-p` flag to all `shell_reset_links_in_dir.bat` script calls to print all assignments

## 2022.12.22:
* :wrench: fixed: src/scripts/scm/shell/shell_reset_links_in_dir.bat: added `-reset-wd-from-target-path` flag to reset `WorkingDirectory` property from `TargetPath` property (shortcut target must not be an existed directory path, otherwise `WorkingDirectory` must be not empty, otherwise - ignore)
* :new: new: deploy/totalcmd/ButtonBars/_common/link/link.bar: added usage of `shell_reset_links_in_dir.bat` with `-reset-wd-from-target-path` flag

## 2022.08.12:
* :wrench: fixed: src/scripts/scm/shell/shell_reset_links_in_dir.bat: execution fixup in case of `)` characters in the path

## 2022.07.02:
* :wrench: fixed: deploy/totalcmd/Profile: profile cleanup and update
* :new: new: deploy/totalcmd/ButtonBars/_common/link/link.bar: shell reset shortcut files in current directory (recursively) item

## 2022.03.14:
* :new: new: deploy/totalcmd/ButtonBars/_common: mklink, _menu.bar: menu for `shell_mklink_by_list.bat` script
* :new: new: res/images/mklink: icons for `shell_mklink_by_list.bat` script

## 2021.10.06:
* :new: new: MinTTY shell terminal support as a standalone submenu

## 2021.10.04:
* :pencil: changed: replaced usage of `mtee.exe` utility by the `callf.exe` utility

## 2022.09.29:
* :new: new: _install.bat, deploy/totalcmd: added option to install a single button menu instead of multiple buttons menu

## 2021.07.21:
* :pencil: changed: removed administrator privileges double elevation in install scripts
* :pencil: changed: replaced usage of `winshell_call.vbs` and `call.vbs` scripts by the `callf.exe` executable with less issues and better functionality

## 2021.05.05:
* :pencil: changed: Now is required to explicitly select the file list to save it into saveload slot, otherwise the empty list would be saved. Has meaning after the `Compare Panels` command (Shift-F2), where the cursor usually points a random file.

## 2021.04.10:
* :wrench: fixed: load/select from utf-8 files w/o BOM [[TC9.51] LOADSEARCH/LOADSELECTION does not work over utf-8 file list w/o BOM](https://www.ghisler.ch/board/viewtopic.php?t=74342)

## 2021.03.12:
* :new: new: `LOADLIST` command usage available in the Total Commander 10b1+

## 2021.03.09:
* :wrench: fixed: immediate exit if copy/move/rename list was not changed

## 2021.03.02:
* :wrench: fixed: shell terminal console input history (up/down buttons) travel
