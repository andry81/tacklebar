> :information_source: this log lists user most visible changes

> :warning: to find all changes use [changelog.txt](https://github.com/andry81/contools/blob/trunk/changelog.txt) file in a directory

## 2021.10.06:
* new: MinTTY shell terminal support as a standalone submenu

## 2021.10.04:
* changed: replaced usage of `mtee.exe` utility by the `callf.exe` utility

## 2021.07.21:
* changed: removed administrator privileges double elevation in install scripts
* changed: replaced usage of `winshell_call.vbs` and `call.vbs` scripts by the `callf.exe` executable with less issues and better functionality

## 2021.05.05:
* changed: Now is required to explicitly select the file list to save it into saveload slot, otherwise the empty list would be saved. Has meaning after the `Compare Panels` command (Shift-F2), where the cursor usually points a random file.

## 2021.04.10:
* fixed: load/select from utf-8 files w/o BOM [[TC9.51] LOADSEARCH/LOADSELECTION does not work over utf-8 file list w/o BOM](https://www.ghisler.ch/board/viewtopic.php?t=74342)

## 2021.03.12:
* new: `LOADLIST` command usage available in the Total Commander 10b1+

## 2021.03.09:
* fixed: immediate exit if copy/move/rename list was not changed

## 2021.03.02:
* fixed: shell terminal console input history (up/down buttons) travel
