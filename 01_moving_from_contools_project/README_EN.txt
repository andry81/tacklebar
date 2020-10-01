* README_EN.txt
* 2020.09.19
* Toolbar buttons configuration for the Total Commander.

1. INSTALLATION
2. CONFIGURATION STORAGE FILES
3. DESCRIPTION ON SCRIPTS USAGE

3.1. Open a notepad window independently to selected files
3.1.1. Method #1. Open a new notepad window to save edit file to current working directory.
3.1.2. Method #2. Open a new notepad window to save edit file to current panel directory.

3.2. Open standalone notepad window for selected files

3.3. Open selected files in existing Notepad++ window

3.4. Open Administator console window in current directory
3.4.1. Method #1. On left mouse button. Total Commander bitness independent.
3.4.2. Method #2. On left mouse button. Total Commander bitness dependent.
3.4.3. Method #3. On right mouse button -> As Administrator.
3.4.4. Method #4. On left mouse button.
3.4.5. Method #5. Call command cmda.bat and Administrator password after.

3.5. Edit SVN properties
3.5.1. Method #1. By path list over SVN GUI.
3.5.2. Method #2. By path list from command line over SVN GUI.
3.5.3. Method #4. By path list over notepad with tabs only for existing externals.
3.5.4. Method #4. By path list over notepad with tabs for selected by user properties including not yet existed.

3.6. Open SVN Log for selected files and directories together
3.6.1. Method #1. By path list over SVN GUI fom wokring copies.
3.6.2. Method #2. By path list over SVN GUI from remmote urls.

3.7. Open TortoiseSVN status dialog for a set of WC directories (always opens to show unversioned changes)
3.7.1. Method #1. (By default if no -window-per-*/-all-in-one flags) One window for all WC directories with or without versioned changes.
3.7.2. Method #2. Window per unique repository root with or without versioned changes in respective WC directory.
3.7.3. Method #3. Window per command line WC directory with or without versioned changes.
3.7.4. Method #4. Window per WC root directory with or without versioned changes.

3.8. Open TortoiseSVN commit dialogs for a set of WC directories
3.8.1. Method #1. (By default if no -window-per-*/-all-in-one flags) Window per unique repository root with changes in respective WC directory.
3.8.2. Method #2. One window for all WC directories with changes.
3.8.3. Method #3. Window per command line WC directory with changes.
3.8.4. Method #4. Window per WC root directory with changes.

3.9 Compare current directories of 2 panels

3.10 Comapre selected paths to path list from a saveload slot

3.11. Compare selected paths from current panel (odd-vs-even)
3.11.1. Method #1. By path list.
3.11.2. Method #3. By path list from command line.

3.12. Compare selected paths from current panel (odd-vs-even, sort file lines)
3.12.1. Method #1. By path list.
3.12.2. Method #2. By path list from command line.

3.13. Shell/SVN/GIT files batch move
3.13.1. Method #1. Move files by path list.

3.14. Shell/SVN/GIT files batch rename
3.14.1. Method #1. Rename files by path list.

3.15. Shell/SVN/GIT files batch copy
3.15.1. Method #1. Copy files by path list.

3.16. Shell file to files copy by path list
3.16.1. Method #1. Shell file to files copy by path list

3.17. Batch create directories in directories
3.17.1. Method #1. Create directories in current directory
3.17.2. Method #2. Create directories in selected directories

3.18. Batch create empty files in directories
3.18.1. Method #1. Create empty files in current directory
3.18.2. Method #2. Create empty files in selected directories

3.19. Batch create directories by path list
3.19.1. Method #1. Create directories by path list.

3.20. Batch create empty files by path list
3.20.1. Method #1. Create empty files by path list.

3.21. Concatenate video files

3.22. Read/Save/Edit/Load/Select path list to/in/from/by a saveload slot
3.22.1. Read file selection list to a saveload slot
3.22.2. Save file selection list to a saveload slot
3.22.3. Edit a saveload slot list
3.22.4. Load file selection list from a saveload slot
3.22.5. Select files by list from a saveload slot

4. AUTHOR

------------------------------------------------------------------------------
1. INSTALLATION
------------------------------------------------------------------------------

1. To install into a directory do run the `_install.bat` with the first
   argument - path to the installation root. The `COMMANDER_SCRIPTS_ROOT`
   environment variable would be created to store the installation path and the
   `tacklelib` subdirectory would contain all the script files and
   configuration files.

2. To use saveload feature to load file selection list from file path lists you
   must execute steps introduced in the
   `Load file selection list from a saveload slot` section of this file!

3. Edit the `profile.vars` file for correct values.

   CAUTION:
      In case if the installation already has been called for a destination
      directory, then the old `profile.vars` would be renamed on next
      installation in the same directory. After the installation you have to
      manually merge values from the old file to the new one.

------------------------------------------------------------------------------
2. CONFIGURATION STORAGE FILES
------------------------------------------------------------------------------

All scripts below would work only if all configuration files would store
correct configuration variables. These configurations files are:

* `profile.vars`

The distribution contains only an example of configuration variables, all the
rest you should figure out on your own.

------------------------------------------------------------------------------
3. DESCRIPTION ON SCRIPTS USAGE
------------------------------------------------------------------------------

All scripts can be called with the console window and without the console
window.

To create a console window use the `call.vbs` or `call_nowait.vbs` script.

To hide a console window use the `call_nowindow.vbs` or
`call_nowindow_nowait.vbs` script.

CAUTION:
  If a `call_nowindow*.vbs` script is used, then you must not use the
  `-pause_on_exit` flag for down layer script otherwise the parent script
  process would pause on exit and because the console window is not visible
  you can not interact with it and you won't be able to close it!

------------------------------------------------------------------------------
3.1. Open a notepad window independently to selected files
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.1.1. Method #1. Open a new notepad window to save edit file to current working directory.
------------------------------------------------------------------------------

For Notepad++:

call.vbs
notepad_new_session.bat -wait -npp -multiInst -nosession

For Windows Notepad:

call.vbs
notepad_new_session.bat -wait

------------------------------------------------------------------------------
3.1.2. Method #2. Open a new notepad window to save edit file to current panel directory.
------------------------------------------------------------------------------

For Notepad++:

call.vbs
notepad_new_session.bat -wait -npp -multiInst -nosession "%P"

For Windows Notepad:

call.vbs
notepad_new_session.bat -wait "%P"

------------------------------------------------------------------------------
3.2. Open standalone notepad window for selected files
------------------------------------------------------------------------------

For Notepad++, ANSI only files (limited by command line length):

call.vbs
notepad_edit_files.bat -wait -npp -nosession -multiInst "%P" %S

For Notepad++, ANSI only files (not limited by command line length):

call.vbs
notepad_edit_files_by_list.bat -npp -nosession -multiInst "%P" %L

For Notepad++, any files (utf-16le, not limited by command line length, but slower):

call.vbs
notepad_edit_files_by_list.bat -npp -paths_to_u16cp -nosession -multiInst "%P" %WL

For Windows Notepad:

call.vbs
notepad_edit_files.bat -wait "%P" %S

------------------------------------------------------------------------------
3.3. Open selected files in existing Notepad++ window
------------------------------------------------------------------------------

ANSI only files (limited by command line length):

call.vbs
notepad_edit_files.bat -wait -npp "%P" %S

ANSI only files (not limited by command line length):

call.vbs
notepad_edit_files_by_list.bat -wait -npp "%P" %L

Any files (utf-16le, not limited by command line length, but slower):

call.vbs
notepad_edit_files_by_list.bat -wait -npp -paths_to_u16cp "%P" %WL

------------------------------------------------------------------------------
3.4. Open Administator console window in current directory
------------------------------------------------------------------------------
CAUTION:
1. Windows can create virtualized `sysnative` directory itself after install or after update rollup with reduced privilege rights, where, for example,
   we can not start `sysnative/cmd.exe` under administrator user.
2. Virtualized `sysnative` directory visible ONLY from 32-bit applications.

For above reasons we should create another directory may be additionally to the `sysnative` one which is:

1. Visible from any application bitness mode.
2. No specific privilege rights restriction by the system and cmd.exe executable from there can be run under administrator user w/o any additional manipulations.

------------------------------------------------------------------------------
3.4.1. Method #1. On left mouse button. Total Commander bitness independent.
------------------------------------------------------------------------------
(may be in some cases it won't work, for example, command "pip install pip --upgrade" in Python 3.5 in Windows 7 x86 responds as "access denided")
(correction: may be the error is an error of Python, the internet advises to run command as: "python -m pip install --upgrade")

In the Windows x64 open 64-bit console window as Administrator user and type:
  mklink /D "%SystemRoot%\System64" "%SystemRoot%\System32"

This will create the directory link to 64-bit cmd.exe available from any bitness process.

For 64-bit cmd.exe button under any mode in the Administrative mode:

cmd_system64_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 32-bit cmd.exe button under any mode in the Administrative mode:

cmd_wow64_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 64-bit cmd.exe button under any mode in a user mode:

cmd_system64.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 32-bit cmd.exe button under any mode in a user mode:

cmd_wow64.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
3.4.2. Method #2. On left mouse button. Total Commander bitness dependent.
------------------------------------------------------------------------------
(In Window x64 will open cmd.exe which bitness will be dependent on
Total Commander bitness)
(may be in some cases it won't work, for example, command "pip install pip --upgrade" in Python 3.5 in Windows 7 x86 responds as "access denided")
(correction: may be the error is an error of Python, the internet advises to run command as: "python -m pip install --upgrade")

cmd_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
3.4.3. Method #2. On right mouse button -> As Administrator.
------------------------------------------------------------------------------

cmd.exe
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
3.4.4. Method #3. On left mouse button.
------------------------------------------------------------------------------
(may be in some cases it won't work, for example, command "netsh winhttp reset proxy" in Windows 7 x86 responds as "access denided")
(in not english version of Windows instead of the "Administrator" you have to use a localized name)

runas
/user:Administrator "cmd.exe /K set \"CWD=%P\\"&call cd /d \"%%CWD%%\"&title User: ^<Administrator^>"

or

cmd_as_user.bat
Administrator "%P"

------------------------------------------------------------------------------
3.4.5. Method #4. Call command cmda.bat and Administrator password after.
------------------------------------------------------------------------------
(cmda.user.bat by default cantains a localized group name of Administrators which uses to take first Administrator name for the console
if cmda.bat didn't have that name at first argument)

cmda.bat
"<Administrator name>"

------------------------------------------------------------------------------
3.5. Edit SVN properties
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.5.1. Method #1. By path list over SVN GUI.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 /command:properties "%P" %WL

For UTF-8 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 /command:properties "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error /command:properties "%P" %L

------------------------------------------------------------------------------
3.5.2. Method #2. By path list from command line over SVN GUI.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc.bat -pause_on_error /command:properties "%P" %S

------------------------------------------------------------------------------
3.5.3. Method #3. By path list over notepad with tabs only for existing externals.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -from_utf16 -edit_filter_by_prop_class -window_per_prop_class "%P" %WL

For UTF-8 path list:

call.vbs
scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -chcp 65001 -edit_filter_by_prop_class -window_per_prop_class "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
3.5.4. Method #4. By path list over notepad with tabs for selected by user properties including not yet existed.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -from_utf16 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P" %WL

For UTF-8 path list:

call.vbs
scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -chcp 65001 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
3.6. Open SVN Log for selected files and directories together
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.6.1. Method #1. By path list over SVN GUI fom wokring copies.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 /command:log "%P" %WL

For UTF-8 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 /command:log "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
3.6.2. Method #2. By path list over SVN GUI from remmote urls.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 -from_url -npp /command:log "%P" %WL

For UTF-8 path list:

call.vbs
scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 -from_url -npp /command:log "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
3.7. Open TortoiseSVN status dialog for a set of WC directories (always opens to show unversioned changes)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.7.1. Method #1. (By default if no -window-per-*/-all-in-one flags) One window for all WC directories with or without versioned changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -all-in-one /command:repostatus "%P" %S

or

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait /command:repostatus "%P" %S

------------------------------------------------------------------------------
3.7.2. Method #2. Window per unique repository root with or without versioned changes in respective WC directory.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-reporoot /command:repostatus "%P" %S

------------------------------------------------------------------------------
3.7.3. Method #3. Window per command line WC directory with or without versioned changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcdir /command:repostatus "%P" %S

------------------------------------------------------------------------------
3.7.4. Method #4. Window per WC root directory with or without versioned changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcroot /command:repostatus "%P" %S

------------------------------------------------------------------------------
3.8. Open TortoiseSVN commit dialogs for a set of WC directories (opens only if has not empty versioned changes).
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.8.1. Method #1. (By default if no -window-per-*/-all-in-one flags) Window per unique repository root with changes in respective WC directory.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-reporoot /command:commit "%P" %S

or

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait /command:commit "%P" %S

------------------------------------------------------------------------------
3.8.2. Method #2. One window for all WC directories with changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -all-in-one /command:commit "%P" %S

------------------------------------------------------------------------------
3.8.3. Method #3. Window per command line WC directory with changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcdir /command:commit "%P" %S

------------------------------------------------------------------------------
3.8.4. Method #4. Window per WC root directory with changes.
------------------------------------------------------------------------------

call.vbs
scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcroot /command:commit "%P" %S

------------------------------------------------------------------------------
3.9 Compare current directories of 2 panels
------------------------------------------------------------------------------

call.vbs
compare_paths.bat -pause_on_exit -chcp 65001 "%X%P" %X%T

------------------------------------------------------------------------------
3.10 Comapre selected paths to path list from a saveload slot
------------------------------------------------------------------------------

call.vbs
compare_paths_by_list.bat -pause_on_exit -from_utf16 "%P" "<file_paths_list_file>" %WL

------------------------------------------------------------------------------
3.11. Compare selected paths from current panel (odd-vs-even)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.11.1. Method #1. By path list.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.11.2. Method #2. By path list from command line.
------------------------------------------------------------------------------

call.vbs
compare_paths.bat -pause_on_exit -chcp 65001 "<path-0>" "<path-1>" ...

------------------------------------------------------------------------------
3.12. Compare selected paths from current panel (odd-vs-even, sort file lines)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.12.1. Method #1. By path list.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit -from_utf16 -sort_file_lines "%P" %WL

For UTF-8 path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit -chcp 65001 -sort_file_lines "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
compare_paths_from_list.bat -pause_on_exit -sort_file_lines "%P" %L

------------------------------------------------------------------------------
3.12.2. Method #2. By path list from command line.
------------------------------------------------------------------------------

call.vbs
compare_paths.bat -pause_on_exit -chcp 65001 -sort_file_lines "<path-0>" "<path-1>" ...

------------------------------------------------------------------------------
3.13. Shell/SVN/GIT files batch move
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
3.13.1. Method #1. Move files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

call.vbs
scm\shell\shell_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

call.vbs
scm\svn\svn_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

call.vbs
scm\git\git_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

call.vbs
scm\shell\shell_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

call.vbs
scm\svn\svn_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

call.vbs
scm\git\git_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

call.vbs
scm\shell\shell_move_by_list.bat -pause_on_exit "%P" %L

For SVN:

call.vbs
scm\svn\svn_move_by_list.bat -pause_on_exit "%P" %L

For GIT:

call.vbs
scm\git\git_move_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.14. Shell/SVN/GIT files batch rename
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
3.14.1. Method #1. Rename files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

call.vbs
scm\shell\shell_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

call.vbs
scm\svn\svn_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

call.vbs
scm\git\git_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

call.vbs
scm\shell\shell_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

call.vbs
scm\svn\svn_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

call.vbs
scm\git\git_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

call.vbs
scm\shell\shell_rename_by_list.bat -pause_on_exit "%P" %L

For SVN:

call.vbs
scm\svn\svn_rename_by_list.bat -pause_on_exit "%P" %L

For GIT:

call.vbs
scm\git\git_rename_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.15. Shell/SVN/GIT files batch copy
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
3.15.1. Method #1. Copy files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

call.vbs
scm\shell\shell_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

call.vbs
scm\svn\svn_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

call.vbs
scm\git\git_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

call.vbs
scm\shell\shell_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

call.vbs
scm\svn\svn_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

call.vbs
scm\git\git_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

call.vbs
scm\shell\shell_copy_by_list.bat -pause_on_exit "%P" %L

For SVN:

call.vbs
scm\svn\svn_copy_by_list.bat -pause_on_exit "%P" %L

For GIT:

call.vbs
scm\git\git_copy_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.16. Shell file to files copy by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.16.1. Method #1. Shell file to files copy by path list
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
copy_file_to_files_by_list.bat -pause_on_exit -from_utf16 -from_file %P%N "<utf-16-path-list-file>"

For UTF-8 path list:

call.vbs
copy_file_to_files_by_list.bat -pause_on_exit -chcp 65001 -from_file %P%N "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
copy_file_to_files_by_list.bat -pause_on_exit -from_file %P%N "<ansi-path-list-file>"

------------------------------------------------------------------------------
3.17. Batch create directories in directories
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.17.1. Method #1. Create directories in current directory
------------------------------------------------------------------------------

For UTF-8:

call.vbs
create_dirs_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P"

For ANSI:

call.vbs
create_dirs_in_dirs_from_list.bat -pause_on_exit "%P"

------------------------------------------------------------------------------
3.17.2. Method #2. Create directories in selected directories
------------------------------------------------------------------------------

For UTF-16 path list:

create_dirs_in_dirs_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

create_dirs_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
create_dirs_in_dirs_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.18. Batch create empty files in directories
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.18.1. Method #1. Create empty files in current directory
------------------------------------------------------------------------------

For UTF-8:

call.vbs
create_empty_files_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P"

For ANSI:

call.vbs
create_empty_files_in_dirs_from_list.bat "%P"

------------------------------------------------------------------------------
3.18.2. Method #2. Create empty files in selected directories
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
create_empty_files_in_dirs_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

call.vbs
create_empty_files_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
create_empty_files_in_dirs_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
3.19. Batch create directories by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.19.1. Method #1. Create directories by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
create_dirs_by_path_list.bat -pause_on_exit -from_utf16 "%P" "<utf-16-path-list-file>"

For UTF-8 path list:

call.vbs
create_dirs_by_path_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
create_dirs_by_path_list.bat -pause_on_exit "%P" "<ansi-path-list-file>"

------------------------------------------------------------------------------
3.20. Batch create empty files by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
3.20.1. Method #1. Create empty files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
create_empty_files_by_path_list.bat -pause_on_exit -from_utf16 "%P" "<utf-16-path-list-file>"

For UTF-8 path list:

call.vbs
create_empty_files_by_path_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
create_empty_files_by_path_list.bat -pause_on_exit "%P" "<ansi-path-list-file>"

------------------------------------------------------------------------------
3.21. Concatenate video files
------------------------------------------------------------------------------

call.vbs
converters\ffmpeg\ffmpeg_convert_by_list.bat -wait -pause_on_exit %L "%T"

------------------------------------------------------------------------------
3.22. Save/Edit/Load/Select path list to/in/from/by a saveload slot
------------------------------------------------------------------------------

To be able to save and load file paths selection list in the Total Commander
for minimal steps or mouse clicks you have to make some preparations before the
usage.

------------------------------------------------------------------------------
3.22.1. Read file selection list to a saveload slot
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

call.vbs
read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
  * `<list_file_name>`  - a list file name there the file paths would be saved.
  * `<list_file_path>`  - a list file directory path there the file paths would
                          be saved.

Note:
  The file name must be by the same path as in the
  `saveload_search_in_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The difference with the `save_file_list.bat` script is that the script steps
into each directory (not recursively) to read the list of files from it.

------------------------------------------------------------------------------
3.22.2. Save file selection list to a saveload slot
------------------------------------------------------------------------------

For UTF-16 path list:

call.vbs
save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

call.vbs
save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

call.vbs
save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
  * `<list_file_name>`  - a list file name there the file paths would be saved.
  * `<list_file_path>`  - a list file directory path there the file paths would
                          be saved.

Note:
  The file name must be by the same path as in the
  `saveload_search_in_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The `save_file_list.bat` script just saves the list of paths to a slot file as
is w/o step in into each directory.

------------------------------------------------------------------------------
3.22.3. Edit a saveload slot list
------------------------------------------------------------------------------

call.vbs
edit_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -wait -npp -multiInst -nosession "<path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
                          before close a console window.
  * `<path_to_file_list>` - a path to list file there the file paths is stored.

------------------------------------------------------------------------------
3.22.4. Load file selection list from a saveload slot
------------------------------------------------------------------------------

At first, you have to create search template in your main configuration file of
the Total Commander in the section `[searches]`:

```
saveload_search_in_utf8_slot_<INDEX_STR>_SearchFor=*.*
saveload_search_in_utf8_slot_<INDEX_STR>_SearchIn=@c:\Total Commander Scripts\.saveload\file_lists\<INDEX_STR>.utf-8.lst
saveload_search_in_utf8_slot_<INDEX_STR>_SearchText=
saveload_search_in_utf8_slot_<INDEX_STR>_SearchFlags=0|103002010021|||||||||0000|0||
```

AND

```
saveload_search_in_utf16le_slot_<INDEX_STR>_SearchFor=*.*
saveload_search_in_utf16le_slot_<INDEX_STR>_SearchIn=@c:\Total Commander Scripts\.saveload\file_lists\<INDEX_STR>.utf-16le.lst
saveload_search_in_utf16le_slot_<INDEX_STR>_SearchText=
saveload_search_in_utf16le_slot_<INDEX_STR>_SearchFlags=0|103002010021|||||||||0000|0||
```

Where the `<INDEX_STR>` must be index string from `01` up to `09` and the path
`c:\Total Commander Scripts\.saveload\file_lists` is an
arbitraty directory there all lists would be saved to and loaded from. You can
create multiple arbitrary empty files in that directory using another command
described here in the section `Create batch empty files`.

NOTE:
  The prefix string `saveload_search_in_*_slot_<INDEX_STR>` is a search
  template name in the `Find Files` dialog in the Total Commander. So instead
  of adding the string in the `[searches]` section, you may create all
  respective templates through the same dialog from the `Load/Save` tab using
  the same values from the example above.

After that you can create any arbitrary number of buttons, but I recommend to
you to create 5 or 10 buttons, not more:

`LOADSEARCH saveload_search_in_utf8_slot_<INDEX_STR>`

AND

`LOADSEARCH saveload_search_in_utf16le_slot_<INDEX_STR>`

Then you can click on the button to open the respective `Find Files` dialog.
Next click to the find button would show the last saved file paths list which
you can feed to the Total Commander last active panel.

------------------------------------------------------------------------------
3.22.5. Select files by list from a saveload slot
------------------------------------------------------------------------------

LOADSELECTION "<path-list-file>"

NOTE:
  Command implemented in the version starting from 9.50 beta 3.

------------------------------------------------------------------------------
4. AUTHOR
------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
