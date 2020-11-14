* README_EN.txt
* 2020.11.15
* tacklebar

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. DEPENDENCIES
6. CATALOG CONTENT DESCRIPTION
7. PROJECT CONFIGURATION VARIABLES
8. INSTALLATION
9. CONFIGURATION STORAGE FILES
10. DESCRIPTION ON SCRIPTS USAGE

10.1. Open a notepad window independently to selected files
10.1.1. Method #1. Open a new notepad window to save edit file to current working directory.
10.1.2. Method #2. Open a new notepad window to save edit file to current panel directory.

10.2. Open standalone notepad window for selected files

10.3. Open selected files in existing Notepad++ window

10.4. Open Administator console window in current directory
10.4.1. Method #1. On left mouse button. Total Commander bitness independent.
10.4.2. Method #2. On left mouse button. Total Commander bitness dependent.
10.4.3. Method #3. On right mouse button -> As Administrator.
10.4.4. Method #4. On left mouse button.
10.4.5. Method #5. Call command cmda.bat and Administrator password after.

10.5. Edit SVN properties
10.5.1. Method #1. By path list over SVN GUI.
10.5.2. Method #2. By path list from command line over SVN GUI.
10.5.3. Method #4. By path list over notepad with tabs only for existing properties.
10.5.4. Method #4. By path list over notepad with tabs for selected by user properties including not yet existed.

10.6. Open SVN Log for selected files and directories together
10.6.1. Method #1. By path list over SVN GUI fom wokring copies.
10.6.2. Method #2. By path list over SVN GUI from remmote urls.

10.7. Open TortoiseSVN status dialog for a set of WC directories (always opens to show unversioned changes)
10.7.1. Method #1. (By default if no -window-per-*/-all-in-one flags) One window for all WC directories with or without versioned changes.
10.7.2. Method #2. Window per unique repository root with or without versioned changes in respective WC directory.
10.7.3. Method #3. Window per command line WC directory with or without versioned changes.
10.7.4. Method #4. Window per WC root directory with or without versioned changes.

10.8. Open TortoiseSVN commit dialogs for a set of WC directories
10.8.1. Method #1. (By default if no -window-per-*/-all-in-one flags) Window per unique repository root with changes in respective WC directory.
10.8.2. Method #2. One window for all WC directories with changes.
10.8.3. Method #3. Window per command line WC directory with changes.
10.8.4. Method #4. Window per WC root directory with changes.

10.9 Compare current directories of 2 panels

10.10 Comapre selected paths to path list from a saveload slot

10.11. Compare selected paths from current panel (odd-vs-even)
10.11.1. Method #1. By path list.
10.11.2. Method #3. By path list from command line.

10.12. Compare selected paths from current panel (odd-vs-even, sort file lines)
10.12.1. Method #1. By path list.
10.12.2. Method #2. By path list from command line.

10.13. Shell/SVN/GIT files batch move
10.13.1. Method #1. Move files by path list.

10.14. Shell/SVN/GIT files batch rename
10.14.1. Method #1. Rename files by path list.

10.15. Shell/SVN/GIT files batch copy
10.15.1. Method #1. Copy files by path list.

10.16. Shell file to files copy by path list
10.16.1. Method #1. Shell file to files copy by path list

10.17. Batch create directories in directories
10.17.1. Method #1. Create directories in current directory
10.17.2. Method #2. Create directories in selected directories

10.18. Batch create empty files in directories
10.18.1. Method #1. Create empty files in current directory
10.18.2. Method #2. Create empty files in selected directories

10.19. Batch create directories by path list
10.19.1. Method #1. Create directories by path list.

10.20. Batch create empty files by path list
10.20.1. Method #1. Create empty files by path list.

10.21. Concatenate video files

10.22. Read/Save/Edit/Load/Select path list to/in/from/by a saveload slot
10.22.1. Read file selection list to a saveload slot
10.22.2. Save file selection list to a saveload slot
10.22.3. Edit a saveload slot list
10.22.4. Load/Select a file list from a saveload slot

11. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Collection of scripts to compare, convert, copy, move, rename, create, edit,
select, operate and etc using file or directory path lists.

Designed to be used with the Total Commander version 9.51 and higher, but can
be adopted to use with, for example, Double Commander.

Sources contains Total Commander button bar files and 32x32 icon files.

------------------------------------------------------------------------------
2. LICENSE
------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://sf.net/p/tacklebar/tacklebar/HEAD/tree/trunk
  * https://svn.code.sf.net/p/tacklebar/tacklebar/trunk
First mirror:
  * https://github.com/andry81/tacklebar/tree/trunk
  * https://github.com/andry81/tacklebar.git
Second mirror:
  * https://bitbucket.org/andry81/tacklebar/src/trunk
  * https://bitbucket.org/andry81/tacklebar.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently used these set of OS platforms, compilers, interpreters, modules,
IDE's, applications and patches to run with or from:

1. OS platforms:

* Windows 7

2. Applications:

* Notepad++ 7.6+
  https://notepad-plus-plus.org
  - Freeware GUI application with various plugins to view/edit text files

* Winmerge
  https://winmerge.org
  - Freeware GUI application to compare/merge text files

* Araxis Merge
  https://www.araxis.com
  - Shareware GUI/console application to compare/merge text files

* ffmpeg
  https://ffmpeg.org
  - Freeware console application to convert/process video files

* TortoiseSVN 1.8+
  https://tortoisesvn.net
 - Freeware GUI/console application to maintain Subversion version control
   system

* Git 2.24+
  https://git-scm.com
  - Freeware console application to maintain GIT version control system

-------------------------------------------------------------------------------
5. DEPENDENCIES
-------------------------------------------------------------------------------
Scripts has using 3dparty applications to maintain various tasks.

* Compare/Merge:

  ** Winmerge
  ** Araxis Merge

* View/Edit:

  ** Notepad++

* Convert:

  ** ffmpeg

* Operate:

  ** svn
  ** git

-------------------------------------------------------------------------------
6. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /`.log`
 |  #
 |  # Default directory with script log files.
 |
 +- /`__init__`
 |  #
 |  # Project root directory initialization scripts.
 |
 +- /`_config`
 |  #
 |  # Directory with build configuration files.
 |
 +- /`_externals`
 |  #
 |  # 3dparty project sources and files.
 |
 +- /`_out`
 |  #
 |  # Temporary directory of generated output from `*.in` files.
 |
 +- /`deploy`
 |  #
 |  # Deploy files like button bar files and etc.
 |
 +- /`dev`
 |  #
 |  # Development tools.
 |
 +- /`res`
 |  #
 |  # Resource files like 32x32 icons for a toolbar buttons.
 |
 +- /`src`
 |  #
 |  # Source files like scripts and local configuration files.
 |
 +- /`_install.bat`
    #
    # Project installation script.

-------------------------------------------------------------------------------
7. PROJECT CONFIGURATION VARIABLES
-------------------------------------------------------------------------------

1. `_config/config.system.vars.in` or
   `_out/config/tacklebar/config.system.vars`

   System variables.

2. `_config/config.0.vars.in` or
   `_out/config/tacklebar/config.0.vars`

   User variables:

* NPP_EDITOR

  File path to the Notepad++ editor executable.

* BASIC_TEXT_EDITOR

  File path to the Windows compatible notepad editor executable to fall back
  to.

* ARAXIS_MERGE_ROOT

  Directory path where the Araxis Merge is installed.

* WINMERGE_ROOT

  Directory path where the Winmerge is installed.

* FFMPEG_TOOL_EXE

  File path to the ffmpeg console utility executable.

------------------------------------------------------------------------------
8. INSTALLATION
------------------------------------------------------------------------------

1. To install into a directory do run the `_install.bat` with the first
   argument - path to the installation root. The `COMMANDER_SCRIPTS_ROOT`
   environment variable would be created to store the installation path and the
   `tacklebar` subdirectory would contain all the script files and
   configuration files.

   NOTE:
      You can call `_install.bat` without the destination path argument in case
      if it has been already called at least once. In that case it would use
      the destination path from the already registered `COMMANDER_SCRIPTS_ROOT`
      variable.

2. To use saveload feature to load or select a file list in a file panel
   you must execute steps introduced in the
   `Load/Select a file list from a saveload slot` section of this file!

3. Edit the `_out/config/tacklebar/config.0.vars` file for correct values.

   CAUTION:
      In case if the installation already has been called for a destination
      directory, then after the installation you have to manually merge values
      from the `config.0.vars` file from the previous installation to the new
      installation.

------------------------------------------------------------------------------
9. CONFIGURATION STORAGE FILES
------------------------------------------------------------------------------

All scripts below would work only if all configuration files would store
correct configuration variables. These configuration files are:

* `_out/config/tacklebar/config.system.vars`
* `_out/config/tacklebar/config.0.vars`

------------------------------------------------------------------------------
10. DESCRIPTION ON SCRIPTS USAGE
------------------------------------------------------------------------------

All scripts can be called with/without:

* environment variables expansion, by default - no expansion (`-E`)
* execution completion await, by default - waits (`-nowait`)
* a console window, by default - shows console window (`-nowindow`)

`%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs` [-E] [-nowait] [-nowindow] <down-layer-script-command-line>

CAUTION:
  The `call.vbs` builtin flags must be preceeded flags of a down layer script
  to be executed.

CAUTION:
  If the `-nowindow` flag of the `call.vbs` script is used, then you must not
  use the `-pause_on_exit` flag in the command line to a down layer script,
  otherwise a script process would pause on exit and because a console window
  is not visible, then you won't be able to interact with it and close it!

CAUTION:
  The `-E` must be always used together with the full file path to the down
  layer script file as long as the Total Commander support command execution
  as Administrator (`As Administrator` in the right click context menu).
  Otherwise the command will fail because the `cscript.exe` interpreter does
  not support a working directory command line parameter and can not set it
  before the execution of a down layer script. So the full file path is a
  mandatory and can be represented as a value of an environment variable,
  so the `-E` builtin flag is used to expand a command line!

------------------------------------------------------------------------------
10.1. Open a notepad window independently to selected files
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.1.1. Method #1. Open a new notepad window to save edit file to current working directory.
------------------------------------------------------------------------------

For Notepad++:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_new_session.bat -wait -npp -multiInst -nosession

For Windows Notepad:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_new_session.bat -wait

------------------------------------------------------------------------------
10.1.2. Method #2. Open a new notepad window to save edit file to current panel directory.
------------------------------------------------------------------------------

For Notepad++:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_new_session.bat -wait -npp -multiInst -nosession "%P"

For Windows Notepad:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_new_session.bat -wait "%P"

------------------------------------------------------------------------------
10.2. Open standalone notepad window for selected files
------------------------------------------------------------------------------

For Notepad++, ANSI only files (limited by command line length):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files.bat -wait -npp -nosession -multiInst "%P" %S

For Notepad++, ANSI only files (not limited by command line length):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat -npp -nosession -multiInst "%P" %L

For Notepad++, any files (utf-16le, not limited by command line length, but slower):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat -npp -paths_to_u16cp -nosession -multiInst "%P" %WL

For Notepad++, any files (utf-16le, not limited by command line length,
has no noticeable slowdown, but the `Python Script` plugin must be installed
together with the `startup.py` script from the `contools` project:
https://sf.net/p/contools/contools/HEAD/tree/trunk/Scripts/Tools/ToolAdaptors/notepadpusplus/scripts/ )

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat -npp -use_npp_extra_cmdline -nosession -multiInst "%P" %WL

For Windows Notepad:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files.bat -wait "%P" %S

------------------------------------------------------------------------------
10.3. Open selected files in existing Notepad++ window
------------------------------------------------------------------------------

ANSI only files (limited by command line length):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files.bat -wait -npp "%P" %S

ANSI only files (not limited by command line length):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat -wait -npp "%P" %L

Any files (utf-16le, not limited by command line length, but slower):

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat -wait -npp -paths_to_u16cp "%P" %WL

------------------------------------------------------------------------------
10.4. Open Administator console window in current directory
------------------------------------------------------------------------------
CAUTION:
1. Windows can create virtualized `sysnative` directory itself after install or after update rollup with reduced privilege rights, where, for example,
   we can not start `sysnative/cmd.exe` under administrator user.
2. Virtualized `sysnative` directory visible ONLY from 32-bit applications.

For above reasons we should create another directory may be additionally to the `sysnative` one which is:

1. Visible from any application bitness mode.
2. No specific privilege rights restriction by the system and cmd.exe executable from there can be run under administrator user w/o any additional manipulations.

------------------------------------------------------------------------------
10.4.1. Method #1. On left mouse button. Total Commander bitness independent.
------------------------------------------------------------------------------
(may be in some cases it won't work, for example, command "pip install pip --upgrade" in Python 3.5 in Windows 7 x86 responds as "access denided")
(correction: may be the error is an error of Python, the internet advises to run command as: "python -m pip install --upgrade")

In the Windows x64 open 64-bit console window as Administrator user and type:
  mklink /D "%SystemRoot%\System64" "%SystemRoot%\System32"

This will create the directory link to 64-bit cmd.exe available from any bitness process.

For 64-bit cmd.exe button under any mode in the Administrative mode:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_system64_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 32-bit cmd.exe button under any mode in the Administrative mode:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_wow64_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 64-bit cmd.exe button under any mode in a user mode:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_system64.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

For 32-bit cmd.exe button under any mode in a user mode:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_wow64.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
10.4.2. Method #2. On left mouse button. Total Commander bitness dependent.
------------------------------------------------------------------------------
(In Window x64 will open cmd.exe which bitness will be dependent on
Total Commander bitness)
(may be in some cases it won't work, for example, command "pip install pip --upgrade" in Python 3.5 in Windows 7 x86 responds as "access denided")
(correction: may be the error is an error of Python, the internet advises to run command as: "python -m pip install --upgrade")

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_admin.lnk
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
10.4.3. Method #2. On right mouse button -> As Administrator.
------------------------------------------------------------------------------

cmd.exe
/K set "CWD=%P"&call cd /d "%%CWD%%"&title %%COMSPEC%%

------------------------------------------------------------------------------
10.4.4. Method #3. On left mouse button.
------------------------------------------------------------------------------
(may be in some cases it won't work, for example, command "netsh winhttp reset proxy" in Windows 7 x86 responds as "access denided")
(in not english version of Windows instead of the "Administrator" you have to use a localized name)

runas
/user:Administrator "cmd.exe /K set \"CWD=%P\\"&call cd /d \"%%CWD%%\"&title User: ^<Administrator^>"

or

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\bat\cmd_as_user.bat
Administrator "%P"

------------------------------------------------------------------------------
10.4.5. Method #4. Call command cmda.bat and Administrator password after.
------------------------------------------------------------------------------
(cmda.user.bat by default cantains a localized group name of Administrators which uses to take first Administrator name for the console
if cmda.bat didn't have that name at first argument)

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\bat\cmda.bat
"<Administrator name>"

------------------------------------------------------------------------------
10.5. Edit SVN properties
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.5.1. Method #1. By path list over SVN GUI.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 /command:properties "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 /command:properties "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error /command:properties "%P" %L

------------------------------------------------------------------------------
10.5.2. Method #2. By path list from command line over SVN GUI.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc.bat -pause_on_error /command:properties "%P" %S

------------------------------------------------------------------------------
10.5.3. Method #3. By path list over notepad with tabs only for existing properties.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -from_utf16 -edit_filter_by_prop_class -window_per_prop_class "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -chcp 65001 -edit_filter_by_prop_class -window_per_prop_class "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
10.5.4. Method #4. By path list over notepad with tabs for selected by user properties including not yet existed.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -from_utf16 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat -pause_on_exit -wait -npp -chcp 65001 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
10.6. Open SVN Log for selected files and directories together
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.6.1. Method #1. By path list over SVN GUI fom wokring copies.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 /command:log "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 /command:log "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
10.6.2. Method #2. By path list over SVN GUI from remmote urls.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -from_utf16 -from_url -npp /command:log "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat -pause_on_error -chcp 65001 -from_url -npp /command:log "%P" "<utf-8-wo-bom-path-list-file>"

------------------------------------------------------------------------------
10.7. Open TortoiseSVN status dialog for a set of WC directories (always opens to show unversioned changes)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.7.1. Method #1. (By default if no -window-per-*/-all-in-one flags) One window for all WC directories with or without versioned changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -all-in-one /command:repostatus "%P" %S

or

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait /command:repostatus "%P" %S

------------------------------------------------------------------------------
10.7.2. Method #2. Window per unique repository root with or without versioned changes in respective WC directory.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-reporoot /command:repostatus "%P" %S

------------------------------------------------------------------------------
10.7.3. Method #3. Window per command line WC directory with or without versioned changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcdir /command:repostatus "%P" %S

------------------------------------------------------------------------------
10.7.4. Method #4. Window per WC root directory with or without versioned changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcroot /command:repostatus "%P" %S

------------------------------------------------------------------------------
10.8. Open TortoiseSVN commit dialogs for a set of WC directories (opens only if has not empty versioned changes).
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.8.1. Method #1. (By default if no -window-per-*/-all-in-one flags) Window per unique repository root with changes in respective WC directory.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-reporoot /command:commit "%P" %S

or

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait /command:commit "%P" %S

------------------------------------------------------------------------------
10.8.2. Method #2. One window for all WC directories with changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -all-in-one /command:commit "%P" %S

------------------------------------------------------------------------------
10.8.3. Method #3. Window per command line WC directory with changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcdir /command:commit "%P" %S

------------------------------------------------------------------------------
10.8.4. Method #4. Window per WC root directory with changes.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat -pause_on_error -chcp 65001 -wait -window-per-wcroot /command:commit "%P" %S

------------------------------------------------------------------------------
10.9 Compare current directories of 2 panels
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths.bat -pause_on_exit -chcp 65001 "%X%P" %X%T

------------------------------------------------------------------------------
10.10 Comapre selected paths to path list from a saveload slot
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_by_list.bat -pause_on_exit -file1_from_utf16 "%P" "<utf-8-file-paths-list-file>" %WL

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_by_list.bat -pause_on_exit -file0_from_utf16 -file1_from_utf16 "%P" "<utf-16-file-paths-list-file>" %WL

------------------------------------------------------------------------------
10.11. Compare selected paths from current panel (odd-vs-even)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.11.1. Method #1. By path list.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.11.2. Method #2. By path list from command line.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths.bat -pause_on_exit -chcp 65001 "<path-0>" "<path-1>" ...

------------------------------------------------------------------------------
10.12. Compare selected paths from current panel (odd-vs-even, sort file lines)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.12.1. Method #1. By path list.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit -from_utf16 -sort_file_lines "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit -chcp 65001 -sort_file_lines "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths_from_list.bat -pause_on_exit -sort_file_lines "%P" %L

------------------------------------------------------------------------------
10.12.2. Method #2. By path list from command line.
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\compare\compare_paths.bat -pause_on_exit -chcp 65001 -sort_file_lines "<path-0>" "<path-1>" ...

------------------------------------------------------------------------------
10.13. Shell/SVN/GIT files batch move
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
10.13.1. Method #1. Move files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_move_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_move_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat -pause_on_exit "%P" %L

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_move_by_list.bat -pause_on_exit "%P" %L

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_move_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.14. Shell/SVN/GIT files batch rename
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
10.14.1. Method #1. Rename files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_rename_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_rename_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat -pause_on_exit "%P" %L

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_rename_by_list.bat -pause_on_exit "%P" %L

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_rename_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.15. Shell/SVN/GIT files batch copy
------------------------------------------------------------------------------

CAUTION:
  All version control (svn/git) scripts would use the shell logic if a version
  control logic is not applicable. For example, if selected files or
  directories is not under version control.

------------------------------------------------------------------------------
10.15.1. Method #1. Copy files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_copy_by_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_copy_by_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat -pause_on_exit "%P" %L

For SVN:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\svn\svn_copy_by_list.bat -pause_on_exit "%P" %L

For GIT:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\scm\git\git_copy_by_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.16. Shell file to files copy by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.16.1. Method #1. Shell file to files copy by path list
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat -pause_on_exit -from_utf16 -from_file %P%N "<utf-16-path-list-file>"

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat -pause_on_exit -chcp 65001 -from_file %P%N "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat -pause_on_exit -from_file %P%N "<ansi-path-list-file>"

------------------------------------------------------------------------------
10.17. Batch create directories in directories
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.17.1. Method #1. Create directories in current directory
------------------------------------------------------------------------------

For UTF-8:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P"

For ANSI:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat -pause_on_exit "%P"

------------------------------------------------------------------------------
10.17.2. Method #2. Create directories in selected directories
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.18. Batch create empty files in directories
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.18.1. Method #1. Create empty files in current directory
------------------------------------------------------------------------------

For UTF-8:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P"

For ANSI:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat "%P"

------------------------------------------------------------------------------
10.18.2. Method #2. Create empty files in selected directories
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat -pause_on_exit -from_utf16 "%P" %WL

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat -pause_on_exit "%P" %L

------------------------------------------------------------------------------
10.19. Batch create directories by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.19.1. Method #1. Create directories by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat -pause_on_exit -from_utf16 "%P" "<utf-16-path-list-file>"

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat -pause_on_exit "%P" "<ansi-path-list-file>"

------------------------------------------------------------------------------
10.20. Batch create empty files by path list
------------------------------------------------------------------------------

------------------------------------------------------------------------------
10.20.1. Method #1. Create empty files by path list.
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat -pause_on_exit -from_utf16 "%P" "<utf-16-path-list-file>"

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat -pause_on_exit -chcp 65001 "%P" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat -pause_on_exit "%P" "<ansi-path-list-file>"

------------------------------------------------------------------------------
10.21. Concatenate video files
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\converters\ffmpeg\ffmpeg_convert_by_list.bat -wait -pause_on_exit %L "%T"

------------------------------------------------------------------------------
10.22. Save/Edit/Load/Select path list to/in/from/by a saveload slot
------------------------------------------------------------------------------

To be able to save and load file paths selection list in the Total Commander
for minimal steps or mouse clicks you have to make some preparations before the
usage.

------------------------------------------------------------------------------
10.22.1. Read file selection list to a saveload slot
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\read_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
  * `<list_file_name>`  - a list file name there the file paths would be saved.
  * `<list_file_path>`  - a list file directory path there the file paths would
                          be saved.

Note:
  The file name must be by the same path as in the
  `saveload_search_from_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The difference with the `save_file_list.bat` script is that the script steps
into each directory (not recursively) to read the list of files from it.

------------------------------------------------------------------------------
10.22.2. Save file selection list to a saveload slot
------------------------------------------------------------------------------

For UTF-16 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\save_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
  * `<list_file_name>`  - a list file name there the file paths would be saved.
  * `<list_file_path>`  - a list file directory path there the file paths would
                          be saved.

Note:
  The file name must be by the same path as in the
  `saveload_search_from_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The `save_file_list.bat` script just saves the list of paths to a slot file as
is w/o step in into each directory.

------------------------------------------------------------------------------
10.22.3. Edit a saveload slot list
------------------------------------------------------------------------------

%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs
-E [-nowait] [-nowindow] %%COMMANDER_SCRIPTS_ROOT%%\tacklebar\src\scripts\saveload\edit_file_list.bat [-pause_on_exit | -pause_on_error | -pause_timeout_sec <pause_timeout_sec>] -wait -npp -multiInst -nosession "<path-list-file>"

Where:
  * `-pause_on_exit`    - always pause on exit.
  * `-pause_on_error`   - pause on exit only if an error.
  * `<pause_timeout_sec>` - timeout in seconds while in a pause (if enabled)
                          before close a console window.
  * `<path_to_file_list>` - a path to list file there the file paths is stored.

------------------------------------------------------------------------------
10.22.4. Load/Select a file list from a saveload slot
------------------------------------------------------------------------------

1. Create search template in your main configuration file of the Total Commander
   in the section `[searches]`:

```
saveload_search_from_utf8_slot_<INDEX_STR>_SearchFor=*.*
saveload_search_from_utf8_slot_<INDEX_STR>_SearchIn=@c:\Total Commander Scripts\.saveload\file_lists\<INDEX_STR>.utf-8.lst
saveload_search_from_utf8_slot_<INDEX_STR>_SearchText=
saveload_search_from_utf8_slot_<INDEX_STR>_SearchFlags=0|103002010021|||||||||0000|0||
```

AND

```
saveload_search_from_utf16le_bom_slot_<INDEX_STR>_SearchFor=*.*
saveload_search_from_utf16le_bom_slot_<INDEX_STR>_SearchIn=@c:\Total Commander Scripts\.saveload\file_lists\<INDEX_STR>.utf-16le-bom.lst
saveload_search_from_utf16le_bom_slot_<INDEX_STR>_SearchText=
saveload_search_from_utf16le_bom_slot_<INDEX_STR>_SearchFlags=0|103002010021|||||||||0000|0||
```

Where the `<INDEX_STR>` must be index string from `01` up to `09` and the path
`c:\Total Commander Scripts\.saveload\file_lists` is an
arbitraty directory there all lists would be saved to and loaded from. You can
create multiple arbitrary empty files in that directory using another command
described here in the section `Batch create empty files in directories`.

NOTE:
  The prefix string `saveload_search_from_*_slot_<INDEX_STR>` is a search
  template name in the `Find Files` dialog in the Total Commander. So instead
  of adding the string in the `[searches]` section, you may create all
  respective templates through the same dialog from the `Load/Save` tab using
  the same values from the example above.

2. Copy the `usercmd.ini` from the `deploy/totalcmd/Profile`
   directory into the Total Commander profile directory near the `wincmd.ini`
   file.

Read the `https://www.ghisler.ch/wiki/index.php/Finding_the_paths_of_Total_Commander_files`
for details.

Then you can click on the `LOAD` button to open the respective `Find Files`
dialog or the `SEL.` button to select files in a file panel.

In case of `LOAD` button a click to the find button in the `Find Files` dialog
would show the last saved file paths list which you can feed to the
Total Commander last active panel.

NOTE:
  The feature is supported in the Total Commander version starting from
  9.50 beta 3.

------------------------------------------------------------------------------
11. AUTHOR
------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
