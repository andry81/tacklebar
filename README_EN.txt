* README_EN.txt
* 2024.01.11
* tacklebar

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. CATALOG CONTENT DESCRIPTION
5. DISTRIBUTION
6. PREREQUISITES
7. DEPENDENCIES
8. EXTERNALS
9. IMPLEMENTATION DETAILS
10. PROJECT CONFIGURATION VARIABLES
11. INSTALLATION
11.1. Windows XP support
12. CONFIGURATION STORAGE FILES
13. DESCRIPTION ON SCRIPTS USAGE
14. SCRIPTS USAGE

14.1. Open a notepad window independently to selected files.
14.1.1. Method #1. Open a new notepad window to save edit file to current
        working directory.
14.1.2. Method #2. Open a new notepad window to save edit file to current panel
        directory.

14.2. Open standalone notepad window for selected files.

14.3. Open selected files in existing Notepad++ window.

14.4. Open Administator console window in current directory.
14.4.1. Method #1. By left mouse button, Total Commander bitness is
        independent.
14.4.2. Method #2. By left mouse button, Total Commander bitness is dependent.
14.4.3. Method #3. By right mouse button, using `As Administrator`.
14.4.4. Method #4. By left mouse button.
14.4.5. Method #5. By call to cmda.bat script and type an Administrator
        password after.

14.5. Edit SVN properties.
14.5.1. Method #1. By path list through the TortoiseSVN GUI.
14.5.2. Method #2. By path list from command line through the TortoiseSVN GUI.
14.5.3. Method #3. By path list over notepad with tabs only for existing
        properties.
14.5.4. Method #4. By path list over notepad with tabs for selected by user
        properties including not yet existed.

14.6. Open SVN Log for selected files and directories together.
14.6.1. Method #1. By path list through the TortoiseSVN GUI from working
        copies.
14.6.2. Method #2. By path list through the TortoiseSVN GUI from remmote urls.

14.7. Open TortoiseSVN status dialog from set of WC directories (always opens
      to show unversioned changes).
14.7.1. Method #1. One window for all WC directories with or without versioned
        changes (by default if no `-window-per-*`/`-all-in-one flags`).
14.7.2. Method #2. Window per unique repository root with or without versioned
        changes in respective WC directory.
14.7.3. Method #3. Window per command line WC directory with or without
        versioned changes.
14.7.4. Method #4. Window per WC root directory with or without versioned
        changes.

14.8. Open TortoiseSVN commit dialogs for a set of WC directories (opens only
      if has not empty versioned changes).
14.8.1. Method #1. Window per unique repository root with versioned changes in
        respective WC directory (by default if no `-window-per-*`/`-all-in-one`
        flags).
14.8.2. Method #2. One window for all WC directories with versioned changes.
14.8.3. Method #3. Window per command line WC directory with versioned changes.
14.8.4. Method #4. Window per WC root directory with versioned changes.

14.9 Compare current directories of 2 panels.

14.10 Comapre selected paths to path list from a saveload slot.

14.11. Compare selected paths from current panel (odd-vs-even).
14.11.1. Method #1. By path list.
14.11.2. Method #2. By path list from command line.

14.12. Compare selected paths from current panel (odd-vs-even, sort file
       lines).
14.12.1. Method #1. By path list.
14.12.2. Method #2. By path list from command line.

14.13. Shell/SVN/GIT files batch move.
14.13.1. Method #1. Move files by path list.

14.14. Shell/SVN/GIT files batch rename.
14.14.1. Method #1. Rename files by path list.

14.15. Shell/SVN/GIT files batch copy.
14.15.1. Method #1. Copy files by path list.

14.16. Shell file to files copy by path list.
14.16.1. Method #1. Shell file to files copy by path list.

14.17. Batch create directories in directories.
14.17.1. Method #1. Create directories in current directory.
14.17.2. Method #2. Create directories in selected directories.

14.18. Batch create empty files in directories.
14.18.1. Method #1. Create empty files in current directory.
14.18.2. Method #2. Create empty files in selected directories.

14.19. Batch create directories by path list.
14.19.1. Method #1. Create directories by path list.

14.20. Batch create empty files by path list.
14.20.1. Method #1. Create empty files by path list.

14.21. Concatenate video files.

14.22. Read/Save/Edit/Load/Select path list to/in/from/by a saveload slot.
14.22.1. Read file selection list to a saveload slot list.
14.22.2. Save file selection list to a saveload slot list.
14.22.3. Edit a saveload slot list.
14.22.4. Load search from a saveload slot list.
14.22.5. Load panel from a saveload slot list.
14.22.6. Select panel files from a saveload slot list.

15. KNOWN ISSUES

15.1. Error message:
      `Windows Script Host is disabled: "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled" = 0x0`
      OR
      `Windows Script Host is disabled: "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled" = 0x0`
      OR
      Error message dialog: `Windows Script Host access is disabled on this machine, Contact your administrator for details`
15.2. A Visual Basic script error message:
      `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
      OR
      A Visual Basic script hangs on execution.
15.3. A script prints error message `the script process is not properly
      elevated up to Administrator privileges.`
15.4. A script shows an error dialog with the title and message:
      `Notepad++.exe - Entry Point Not Found`,
      `The procedure entry point GetLogicalProcessorInformation could not be located in the dynamic link library KERNEL32.dll`
15.5. A script shows GUI error dialog with the title and message:
      `notepad++.exe - Entry Point Not Found`,
      `The procedure entry point SHCreateItemFromParsingName count not be located in the dynamic link library SHELL32.dll.`
15.6. A script shows an error dialog with the title and message:
      `Notepad++.exe - Unable To Locate Component`,
      `This application has failed to start because python27.dll was not found. Re-installing the application may fix this problem.`
15.7. Cygwin/Msys console input stalls with the error message:
      `tee: 'standard output': Permission denied`.
15.8. Parent `cmd.exe` console window does not hide after the open of the
      ConEmu console window GUI.
15.9. Parent `cmd.exe` console window does not close after the close of the
      ConEmu console window GUI.
15.10. Parent `cmd.exe` console process closes upon the open of the ConEmu
       console window GUI and ConEmu console window opens with wrong `cmd.exe`
       bitness instance.
       OR
       ConEmu console window prints multiple error messages:
       `The process tried to write to a nonexistent pipe.` when runs 2 or more
       console instances.
15.11. A script print error message
       `/usr/bin/bash: line 0: cd: ...: No such file or directory`
15.12. A script shows GUI error dialog `Windows Script Host`:
       `Script: ...\call.vbs Line: ... Column: ... Error: Invalid procedure call or argument Code: 800A0005 Source: Microsoft VBScript runtime error`
15.13. ffmpeg prints multiple error messages while concatenating video files:
       `non-existing PPS 0 referenced`, `decode_slice_header error`

15. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Collection of scripts to compare, convert, copy, move, rename, create, edit,
select, operate and etc using file or directory path lists.

Designed to be used with the Total Commander version 9.51 and higher, but can
be adopted to use with, for example, Double Commander.

Sources contains Total Commander button bar files and 32x32 icon files.

-------------------------------------------------------------------------------
2. LICENSE
-------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://github.com/andry81/tacklebar/branches
  * https://github.com/andry81/tacklebar.git
First mirror:
  * https://sf.net/p/tacklebar/tacklebar/ci/master/tree
  * https://git.code.sf.net/p/tacklebar/tacklebar
Second mirror:
  * https://gitlab.com/andry81/tacklebar/-/branches
  * https://gitlab.com/andry81/tacklebar.git

-------------------------------------------------------------------------------
4. CATALOG CONTENT DESCRIPTION
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
 |  # Deploy files like button bar files, fonts and etc.
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
 |  #
 |  # Main installation script.
 |
 +- /`_install-fonts.bat`
    #
    # Optional terminal fonts installation script.

-------------------------------------------------------------------------------
5. DISTRIBUTION
-------------------------------------------------------------------------------
See details in the `DISTRIBUTION` section of the `README_EN.txt` file from the
`tacklebar--external_tools` project.

-------------------------------------------------------------------------------
6. PREREQUISITES
-------------------------------------------------------------------------------

Currently used these set of OS platforms, externals and applications to run
with or from:

1. OS platforms:

* Windows XP x86 SP2/x64 SP1
* Windows 7+

2. Externals:

  * `contools`
  * `gitcmd`
  * `svncmd`
  * `tacklelib`

3. Applications:

* MinTTY
  https://mintty.github.io
  https://github.com/mintty/mintty
  - Mintty is a terminal emulator for Cygwin, MSYS or Msys2, and derived
    projects, and for WSL.

* ConEmu 201124+
  https://github.com/Maximus5/ConEmu
  - Freeware Windows console emulator with tabs, which represents multiple
    consoles as one customizable GUI window with various features.

* Notepad++ 7.6+
  https://notepad-plus-plus.org
  - Freeware GUI application with various plugins to view/edit text files.

* Notepad++ PythonScript plugin
  https://github.com/bruderstein/PythonScript
  - Freeware Notepad++ python plugin to run python scripts in the Notepad++.

* Winmerge
  https://winmerge.org
  - Freeware GUI application to compare/merge text files.

* Araxis Merge
  https://www.araxis.com
  - Shareware GUI/console application to compare/merge text files.

* ffmpeg
  https://ffmpeg.org/download.html#build-windows
  https://github.com/BtbN/FFmpeg-Builds/releases,
  https://github.com/Reino17/ffmpeg-windows-build-helpers
  https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D
  - Freeware console application to convert/process video files.

* msys2
  https://www.msys2.org/#installation
  - Freeware Unix-like environment for the Windows.

* cygwin
  https://cygwin.com
  - Freeware Unix-like environment for the Windows.

* TortoiseSVN 1.8+
  https://tortoisesvn.net
 - Freeware GUI/console application to maintain Subversion version control
   system.

* Git 2.24+
  https://git-scm.com
  - Freeware console application to maintain GIT version control system.

* GitExtensions
  https://github.com/gitextensions/gitextensions
  - Freeware GUI application to maintain GIT version control system.

* Visual C++ 2008 Redistributables
  https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243
  - Dependency for the Python 2.7.x DLL linked with Notepad++ PythonScript
    plugin.

NOTE:
  Exact versions see in the configuration file from `_config` directory.

Scripts has using 3dparty applications to maintain various tasks.

* Compare/Merge:

  ** Winmerge
  ** Araxis Merge

* View/Edit:

  ** Notepad++

* Convert:

  ** ffmpeg

* Operate:

  ** MinTTY
  ** ConEmu
  ** svn
  ** git
  ** GitExtensions

-------------------------------------------------------------------------------
7. DEPENDENCIES
-------------------------------------------------------------------------------

Any project which is dependent on this project have has to contain the
`README_EN.deps.txt` description file for the common dependencies in the
Windows and in the Linux like platforms (see `PRECONFIGURE` section).

-------------------------------------------------------------------------------
8. EXTERNALS
-------------------------------------------------------------------------------
To checkout externals you must use the
[vcstool](https://github.com/dirk-thomas/vcstool) python module.

NOTE:
  To install the module from the git repository:

  >
  python -m pip install git+https://github.com/dirk-thomas/vcstool

CAUTION:
  To use the sparse checkout feature you must use a forked repository:

  >
  python -m pip install git+https://github.com/aaronplusone/vcstool@feature-sparse-checkouts

    Or

  >
  python -m pip install git+https://github.com/plusone-robotics/vcstool@por_master

-------------------------------------------------------------------------------
9. IMPLEMENTATION DETAILS
-------------------------------------------------------------------------------

List of issues discovered in Windows XP/7:

1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7)
   brings truncated command line down to ~260 characters.
2. Run from shortcut file (`.lnk`) loads console windows parameters (font,
   windows size, buffer size, etc) from the shortcut at first and from the
   registry (HKCU\Console) at second. If try to change and save parameters,
   then saves ONLY into the shortcut, which brings the shortcut file overwrite.
3. Run under UAC promotion in the Windows 7+ blocks environment inheritance,
   blocks stdout redirection into a pipe from non-elevated process into
   elevated one and blocks console screen buffer change (piping locks process
   (stdout) screen buffer sizes).
   To bypass that, for example, need to:
    a. Save environment variables to a file from non-elevated process and load
       them back in an elevated process.
    b. Use redirection only from an elevated process.
    c. Change console screen buffer sizes before stdout redirection into a
       pipe.
4. Windows antivirus software in some cases reports a `.vbs` script as not safe
   or requests an explicit action on each `.vbs` script execution.

To resolve all the issues we DO NOT USE shortcut files (`.lnk`) or Visual Basic
scripts (`.vbs`) for UAC promotion.
The latest implementation does use instead as a replacement the `callf.exe`
utility.

NOTE:
  An old implementation still may use winshell_call.vbs` + `call.vbs` scripts.

PROs:
  1. Implementation is the same and portable between all the Windows versions
     like Windows XP/7/8/10. No need to use different implementations for each
     Windows version.
  2. No need to change console windows parameters (font, windows sizes, buffer
     sizes, etc) each time the project is installed. The parameters loads/saves
     from/to the registry and so is shared between installations.
  3. Process inheritance tree is retained between non-elevated process and
     elevated process because parent non-elevated process (`callf.exe`) awaits
     child elevated process.
  4. A single console can be shared between non-elevated and elevated
     processes.
  5. A single log file can be shared between non-elevated and elevated
     processes.
  6. The `/pause-on-exit*` flags of the `callf.exe` does not block execution
     on detached console versus the `pause` command of the `cmd.exe`
     interpreter which does block.

CONs:
  1. The `callf.exe` still can not redirect stdin/stdout of a child `cmd.exe`
     process without losing the auto completion feature (in case of interactive
     input - `cmd.exe /k`).

-------------------------------------------------------------------------------
10. PROJECT CONFIGURATION VARIABLES
-------------------------------------------------------------------------------

1. `_config/config.system.vars.in` or
   `_out/config/tacklebar/config.system.vars`

   System variables.

2. `_config/config.0.vars.in` or
   `_out/config/tacklebar/config.0.vars`

   User variables.

* USE_MINTTY

  Enables use of mintty in all scripts by default.

* MINTTY32_ROOT
* MINTTY64_ROOT

  Directory path where the Mintty is installed.

* USE_CONEMU

  Enables use of conemu in all scripts by default.

* CONEMU_INTERACT_MODE
  CONEMU_ROOT
  CONEMU_CMD32_CMDLINE_ATTACH_PREFIX
  CONEMU_CMD64_CMDLINE_ATTACH_PREFIX
  CONEMU_CMD32_CMDLINE_RUN_PREFIX
  CONEMU_CMD64_CMDLINE_RUN_PREFIX

  The ConEmu related variables.

* NPP_EDITOR

  File path to the Notepad++ editor executable.

* BASIC_TEXT_EDITOR

  File path to the Windows compatible notepad editor executable to fall back
  to.

* MSYS32_ROOT
* MSYS64_ROOT

  Directory path where the Msys is installed.

* CYGWIN32_ROOT
* CYGWIN64_ROOT

  Directory path where the Cygwin is installed.

* ARAXIS_MERGE_ROOT

  Directory path where the Araxis Merge is installed.

* ARAXIS_COMPARE_ENABLE

  Use Araxis compare tool to compare files and directories.

* ARAXIS_COMPARE_TOOL
* ARAXIS_CONSOLE_COMPARE_TOOL
* ARAXIS_CONSOLE_COMPARE_TOOL_FLAGS

  Araxis compare tool executable and default command line flags.

* WINMERGE_ROOT

  Directory path where the Winmerge is installed.

* WINMERGE_COMPARE_TOOL
* WINMERGE_COMPARE_TOOL_FLAGS

  Winmerge compare tool executable and default command line flags.

* GIT_SHELL_ROOT

  Directory path with the POSIX subdirectories (/bin) where the Bash shell is
  installed. The GitForWindows, Cygwin or Msys can be used.

* GITEXTENSIONS_ROOT

  Directory path where the GitExtensions is installed.

* FFMPEG_TOOL_EXE

  File path to the ffmpeg console utility executable.

-------------------------------------------------------------------------------
11. INSTALLATION
-------------------------------------------------------------------------------

1. To install into a directory without a GUI do run the `_install.bat` with
   optional first argument - path to the installation root:

   >
   mkdir c:\totalcmd\scripts
   _install.bat c:\totalcmd\scripts

   If the first argument is not defined and `COMMANDER_SCRIPTS_ROOT` variable
   is not set then, the GUI directory selection dialog would appear.

   The `COMMANDER_SCRIPTS_ROOT` environment variable would be created to store
   the installation path and the `tacklebar` subdirectory would contain all
   the script files and configuration files.

   NOTE:
      You can call `_install.bat` without the destination path argument in case
      if it has been already called at least once. In that case it would use
      the destination path from the already registered `COMMANDER_SCRIPTS_ROOT`
      variable.

   NOTE:
      The latest implementation does suggest the
      `%COMMANDER_PATH%\plugins\UTIL` path as a default installation root.
      This exists to potentially avoid a write protection on the Total
      Commander directory (`/W` flag for the installer, see for details
      https://www.ghisler.com/history.txt) and keep the Total Commander root
      directory clean.

2. At the end of the installation script execution does edit the
   `_out/config/tacklebar/config.0.vars` file for correct values.

   CAUTION:
      In case if the installation already has been called at least once and
      configuration values between a previous installation and the new one are
      different then, at the end of the installation you will be asked to
      merge values (using a merge application) from the `config.0.vars` file
      of the previous installation directory into the `config.0.vars` file of
      new installation directory (basically a new installation directory has
      the same location as previous one).

3. Optionally install fonts from the `deploy/fonts` directory by run the
   `_install-fonts.bat` script.

NOTE:
  In the Windows XP the `_install.bat` and `_install-fonts.bat` scripts has a
  builtin UAC promotion which works when the option
  `Protect my computer and data from unauthorized program activity` in the
  `Run As` dialog is deselected!

-------------------------------------------------------------------------------
11.1. Windows XP support
-------------------------------------------------------------------------------

For the Windows XP the initial codepage in the `config.system.vars`
configuration file is taken from the registry on the moment of the
installation. You can change it:

(DOS codepage)

>
mkdir c:\totalcmd\scripts
_install.bat -chcp 866 c:\totalcmd\scripts

>
_install-fonts.bat -chcp 866

-------------------------------------------------------------------------------
12. CONFIGURATION STORAGE FILES
-------------------------------------------------------------------------------

All scripts below would work only if all configuration files would store
correct configuration variables. These configuration files are:

* `_out/config/tacklebar/config.system.vars`
* `_out/config/tacklebar/config.0.vars`

-------------------------------------------------------------------------------
13. DESCRIPTION ON SCRIPTS USAGE
-------------------------------------------------------------------------------

All scripts can be called with the
`%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Utilities\bin\contools\callf.exe`
utility assistance:

Usage:
  >
  callf.exe [/?] [<Flags>] [//] <ApplicationNameFormatString>
    [<CommandLineFormatString> [<Arg1> [<Arg2> ... [<ArgN>]]]]
  >
  callf.exe [/?] [<Flags>] /shell-exec <Verb> [//] <FilePathFormatString>
    [<ParametersFormatString> [<Arg1> [<Arg2> ... [<ArgN>]]]]

Run utility `callf.exe /?` to print full help.

CAUTION:
  You should escape each backslash (`\`) character on the end of each command
  line argument of an executable (an internal Windows shell issue).

  Example:
    1. >
       callf.exe ... "<path-with-trailing-backslash-character>\"
    2. >
       callf.exe ... "<path-with-or-without-trailing-backslash-character>\."

  This will prevent from an argument trailing quote accident escaping.

CAUTION:
  If the `/no-window` flag of the `callf.exe` utility is used then, you must
  not use the `-pause_on_exit` flag in the command line to a down layer script,
  otherwise a script process would pause on exit and because a console window
  is not visible then, you won't be able to interact with it and close it!
  In that case you can use instead `/pause-on-exit*` flags of the `callf.exe`
  utility which does not block execution on detached console.


Old implementation scripts can be called with the `call.vbs` script assistance:

USAGE:
  >
  "%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\vbs\call.vbs"
  <command-line>

See the `call.vbs` file header for full help.

-------------------------------------------------------------------------------
14. SCRIPTS USAGE
-------------------------------------------------------------------------------
Here and after all the scripts is used in conjuction with the Total Commander
buttons bar environment. For example, variables like `%P` and `%WL` does
substitute by the Total Commander button bar menu command.

To read about the Total Commander button bar use the builtin help:
press F1 and search for the `button bar` keywords.

-------------------------------------------------------------------------------
14.1. Open a notepad window independently to selected files.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.1.1. Method #1. Open a new notepad window to save edit file to current
        working directory.
-------------------------------------------------------------------------------

For Notepad++:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_new_session.bat"
-wait -npp -multiInst -nosession

For Windows Notepad:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_new_session.bat"
-wait

-------------------------------------------------------------------------------
14.1.2. Method #2. Open a new notepad window to save edit file to current panel
        directory.
-------------------------------------------------------------------------------

For Notepad++:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_new_session.bat"
-wait -npp -multiInst -nosession "%P\."

For Windows Notepad:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_new_session.bat"
-wait "%P\."

-------------------------------------------------------------------------------
14.2. Open standalone notepad window for selected files.
-------------------------------------------------------------------------------

For Notepad++, ANSI only files (limited by command line length):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files.bat"
-wait -npp -nosession -multiInst "%P\." %S

For Notepad++, ANSI only files (not limited by command line length):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat"
-npp -nosession -multiInst "%P\." %L

For Notepad++, any files (utf-16le, not limited by command line length, but
slower):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat"
-npp -paths_to_u16cp -nosession -multiInst "%P\." %WL

For Notepad++, any files (utf-16le, not limited by command line length,
has no noticeable slowdown, but the `Python Script` plugin must be installed
together with the `startup.py` script from the `contools` project:
https://sf.net/p/contools/contools/HEAD/tree/trunk/Scripts/Tools/ToolAdaptors/notepadplusplus/scripts/)

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat"
-npp -use_npp_extra_cmdline -nosession -multiInst "%P\." %WL

For Windows Notepad:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files.bat"
-wait "%P\." %S

-------------------------------------------------------------------------------
14.3. Open selected files in existing Notepad++ window.
-------------------------------------------------------------------------------

ANSI only files (limited by command line length):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files.bat"
-wait -npp "%P\." %S

ANSI only files (not limited by command line length):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat"
-wait -npp "%P\." %L

Any files (utf-16le, not limited by command line length, but slower):

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\notepad\notepad_edit_files_by_list.bat"
-wait -npp -paths_to_u16cp "%P\." %WL

-------------------------------------------------------------------------------
14.4. Open Administator console window in current directory.
-------------------------------------------------------------------------------
CAUTION:
  1. The `Sysnative/cmd.exe` can not be run under the Administrator user.
  2. The `Sysnative` directory visible ONLY from 64-bit applications.
  3. The `Sysnative` directory doesn't exist on the Windows XP x64 and lower.

For above reasons we should create another directory additionally to the
`sysnative` one which is:

1. Visible from any application bitness mode and the Windows version.
2. No specific privilege rights restriction by the system and `cmd.exe`
   executable from there can be run under administrator user w/o any additional
   manipulations.

-------------------------------------------------------------------------------
14.4.1. Method #1. By left mouse button, Total Commander bitness is
        independent.
-------------------------------------------------------------------------------
NOTE:
  May be in some cases it won't work, for example, command
  `pip install pip --upgrade` in the Python 3.5 in the Windows 7 x86
  responds as "access denided".
  But may be the error is an error of Python, the internet advises to run
  command as: "python -m pip install --upgrade"

In the Windows x64 open 64-bit console window as Administrator user and type:

  >
  mklink /D "%SystemRoot%\System64" "%SystemRoot%\System32"

This will create the directory link to 64-bit `cmd.exe` available from any
bitness process.

For 64-bit `cmd.exe` button under any mode in the Administrative mode:

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_system64_admin.lnk
/K cd /d "%P\."&call title %%COMSPEC%%: %%CD%%

For 32-bit `cmd.exe` button under any mode in the Administrative mode:

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_wow64_admin.lnk
/K cd /d "%P\."&call title %%COMSPEC%%: %%CD%%

For 64-bit `cmd.exe` button under any mode in a user mode:

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_system64.lnk
/K cd /d "%P\."&call title %%COMSPEC%%: %%CD%%

For 32-bit `cmd.exe` button under any mode in a user mode:

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_wow64.lnk
/K cd /d "%P\."&call title %%COMSPEC%%: %%CD%%

-------------------------------------------------------------------------------
14.4.2. Method #2. By left mouse button, Total Commander bitness is dependent.
-------------------------------------------------------------------------------
NOTE:
  1. In the Windows x64 will open `cmd.exe` which bitness will be dependent on
     the Total Commander bitness.
  2. May be in some cases it won't work, for example, command
     `pip install pip --upgrade` in the Python 3.5 in the Windows 7 x86
     responds as "access denided".
     But may be the error is an error of Python, the internet advises to run
     command as: "python -m pip install --upgrade"

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\lnk\cmd_admin.lnk
/K cd /d "%P\."&title %COMSPEC%

-------------------------------------------------------------------------------
14.4.3. Method #3. By right mouse button, using `As Administrator`.
-------------------------------------------------------------------------------

>
cmd.exe
/K cd /d "%P\."&title %COMSPEC%

-------------------------------------------------------------------------------
14.4.4. Method #4. By left mouse button.
-------------------------------------------------------------------------------
NOTE:
  1. May be in some cases it won't work, for example, command
     `pip install pip --upgrade` in the Python 3.5 in the Windows 7 x86
     responds as "access denided".
     But may be the error is an error of Python, the internet advises to run
     command as: "python -m pip install --upgrade"
  2. In non english version of the Windows instead of the "Administrator" you
     have to use a localized name.

>
runas
/user:Administrator "cmd.exe /K cd /d \"%P\.\"&title User: ^<Administrator^>"

or

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\bat\cmd_as_user.bat
Administrator "%P\."

-------------------------------------------------------------------------------
14.4.5. Method #5. By call to cmda.bat script and type an Administrator password after.
-------------------------------------------------------------------------------
NOTE:
  the `cmda.user.bat` script by default contains a localized group name of the
  `Administrators` which uses to take the first administrator name for the
  console if the `cmda.bat` script didn't have that name as first argument.

>
%COMMANDER_SCRIPTS_ROOT%\tacklebar\_externals\contools\Scripts\Tools\ToolAdaptors\bat\cmda.bat
"<Administrator name>"

-------------------------------------------------------------------------------
14.5. Edit SVN properties.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.5.1. Method #1. By path list through the TortoiseSVN GUI.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-from_utf16 /command:properties "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-chcp 65001 /command:properties "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
/command:properties "%P\." %L

-------------------------------------------------------------------------------
14.5.2. Method #2. By path list from command line through the TortoiseSVN GUI.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc.bat"
/command:properties "%P\." %S

-------------------------------------------------------------------------------
14.5.3. Method #3. By path list over notepad with tabs only for existing properties.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat"
-wait -npp -from_utf16 -edit_filter_by_prop_class -window_per_prop_class "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat"
-wait -npp -chcp 65001 -edit_filter_by_prop_class -window_per_prop_class "%P\." "<utf-8-wo-bom-path-list-file>"

-------------------------------------------------------------------------------
14.5.4. Method #4. By path list over notepad with tabs for selected by user
        properties including not yet existed.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat"
-wait -npp -from_utf16 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\svn\svn_edit_props_by_list.bat"
-wait -npp -chcp 65001 -edit_filter_by_prop_class -create_prop_if_empty -window_per_prop_class "%P\." "<utf-8-wo-bom-path-list-file>"

-------------------------------------------------------------------------------
14.6. Open SVN Log for selected files and directories together.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.6.1. Method #1. By path list through the TortoiseSVN GUI from working
        copies.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-from_utf16 /command:log "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-chcp 65001 /command:log "%P\." "<utf-8-wo-bom-path-list-file>"

-------------------------------------------------------------------------------
14.6.2. Method #2. By path list through the TortoiseSVN GUI from remmote urls.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-from_utf16 -from_url -npp /command:log "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_list.bat"
-chcp 65001 -from_url -npp /command:log "%P\." "<utf-8-wo-bom-path-list-file>"

-------------------------------------------------------------------------------
14.7. Open TortoiseSVN status dialog from set of WC directories (always opens
      to show unversioned changes).
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.7.1. Method #1. One window for all WC directories with or without versioned
        changes (by default if no `-window-per-*`/`-all-in-one flags`).
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -all-in-one /command:repostatus "%P\." %S

or

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait /command:repostatus "%P\." %S

-------------------------------------------------------------------------------
14.7.2. Method #2. Window per unique repository root with or without versioned
        changes in respective WC directory.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-reporoot /command:repostatus "%P\." %S

-------------------------------------------------------------------------------
14.7.3. Method #3. Window per command line WC directory with or without
        versioned changes.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-wcdir /command:repostatus "%P\." %S

-------------------------------------------------------------------------------
14.7.4. Method #4. Window per WC root directory with or without versioned
        changes.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-wcroot /command:repostatus "%P\." %S

-------------------------------------------------------------------------------
14.8. Open TortoiseSVN commit dialogs for a set of WC directories (opens only
      if has not empty versioned changes).
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.8.1. Method #1. Window per unique repository root with versioned changes in
        respective WC directory (by default if no `-window-per-*`/`-all-in-one`
        flags).
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-reporoot /command:commit "%P\." %S

or

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait /command:commit "%P\." %S

-------------------------------------------------------------------------------
14.8.2. Method #2. One window for all WC directories with versioned changes.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -all-in-one /command:commit "%P\." %S

-------------------------------------------------------------------------------
14.8.3. Method #3. Window per command line WC directory with versioned changes.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-wcdir /command:commit "%P\." %S

-------------------------------------------------------------------------------
14.8.4. Method #4. Window per WC root directory with versioned changes.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\tortoisesvn\tortoiseproc_by_nested_wc.bat"
-chcp 65001 -wait -window-per-wcroot /command:commit "%P\." %S

-------------------------------------------------------------------------------
14.9 Compare current directories of 2 panels.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths.bat"
-chcp 65001 "%X%P" %X%T

-------------------------------------------------------------------------------
14.10 Comapre selected paths to path list from a saveload slot.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_by_list.bat"
-file1_from_utf16 "%P\." "<utf-8-file-paths-list-file>" %WL

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_by_list.bat"
-file0_from_utf16 -file1_from_utf16 "%P\." "<utf-16-file-paths-list-file>" %WL

-------------------------------------------------------------------------------
14.11. Compare selected paths from current panel (odd-vs-even).
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.11.1. Method #1. By path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
-from_utf16 "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
"%P\." %L

-------------------------------------------------------------------------------
14.11.2. Method #2. By path list from command line.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths.bat"
-chcp 65001 "<path-0>" "<path-1>" ...

-------------------------------------------------------------------------------
14.12. Compare selected paths from current panel (odd-vs-even, sort file
       lines).
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.12.1. Method #1. By path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
-from_utf16 -sort_file_lines "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
-chcp 65001 -sort_file_lines "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths_from_list.bat"
-sort_file_lines "%P\." %L

-------------------------------------------------------------------------------
14.12.2. Method #2. By path list from command line.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\compare\compare_paths.bat"
-chcp 65001 -sort_file_lines "<path-0>" "<path-1>" ...

-------------------------------------------------------------------------------
14.13. Shell/SVN/GIT files batch move.
-------------------------------------------------------------------------------

CAUTION:
  The script would use the shell logic if a version control logic is not
  applicable. For example, if selected files or directories is not under
  version control.

-------------------------------------------------------------------------------
14.13.1. Method #1. Move files by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-from_utf16 "%P\." %WL

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_svn -from_utf16 "%P\." %WL

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_git -from_utf16 "%P\." %WL

For UTF-8 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_svn -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_git -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
"%P\." %L

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_svn "%P\." %L

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_move_by_list.bat"
-use_git "%P\." %L

-------------------------------------------------------------------------------
14.14. Shell/SVN/GIT files batch rename.
-------------------------------------------------------------------------------

CAUTION:
  The script would use the shell logic if a version control logic is not
  applicable. For example, if selected files or directories is not under
  version control.

-------------------------------------------------------------------------------
14.14.1. Method #1. Rename files by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-from_utf16 "%P\." %WL

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_svn -from_utf16 "%P\." %WL

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_git -from_utf16 "%P\." %WL

For UTF-8 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_svn -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_git -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
"%P\." %L

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_svn "%P\." %L

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_rename_by_list.bat"
-use_git "%P\." %L

-------------------------------------------------------------------------------
14.15. Shell/SVN/GIT files batch copy.
-------------------------------------------------------------------------------

CAUTION:
  The script would use the shell logic if a version control logic is not
  applicable. For example, if selected files or directories is not under
  version control.

-------------------------------------------------------------------------------
14.15.1. Method #1. Copy files by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-from_utf16 "%P\." %WL

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_svn -from_utf16 "%P\." %WL

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_git -from_utf16 "%P\." %WL

For UTF-8 path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_svn -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_git -chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

For Shell:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
"%P\." %L

For SVN:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_svn "%P\." %L

For GIT:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\scm\shell\shell_copy_by_list.bat"
-use_git "%P\." %L

-------------------------------------------------------------------------------
14.16. Shell file to files copy by path list.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.16.1. Method #1. Shell file to files copy by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat"
-from_utf16 -from_file %P%N "<utf-16-path-list-file>"

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat"
-chcp 65001 -from_file %P%N "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\copy\copy_file_to_files_by_list.bat"
-from_file %P%N "<ansi-path-list-file>"

-------------------------------------------------------------------------------
14.17. Batch create directories in directories.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.17.1. Method #1. Create directories in current directory.
-------------------------------------------------------------------------------

For UTF-8:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat"
-chcp 65001 "%P\."

For ANSI:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat"
"%P\."

-------------------------------------------------------------------------------
14.17.2. Method #2. Create directories in selected directories.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat"
-from_utf16 "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_in_dirs_from_list.bat"
"%P\." %L

-------------------------------------------------------------------------------
14.18. Batch create empty files in directories.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.18.1. Method #1. Create empty files in current directory.
-------------------------------------------------------------------------------

For UTF-8:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat"
-chcp 65001 "%P\."

For ANSI:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat"
"%P\."

-------------------------------------------------------------------------------
14.18.2. Method #2. Create empty files in selected directories.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat"
-from_utf16 "%P\." %WL

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_in_dirs_from_list.bat"
"%P\." %L

-------------------------------------------------------------------------------
14.19. Batch create directories by path list.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.19.1. Method #1. Create directories by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat"
-from_utf16 "%P\." "<utf-16-path-list-file>"

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_dirs_by_path_list.bat"
"%P\." "<ansi-path-list-file>"

-------------------------------------------------------------------------------
14.20. Batch create empty files by path list.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
14.20.1. Method #1. Create empty files by path list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat"
-from_utf16 "%P\." "<utf-16-path-list-file>"

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat"
-chcp 65001 "%P\." "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\create\create_empty_files_by_path_list.bat"
"%P\." "<ansi-path-list-file>"

-------------------------------------------------------------------------------
14.21. Concatenate video files.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\converters\ffmpeg\ffmpeg_concat_by_list.bat"
-wait %L "%T"

-------------------------------------------------------------------------------
14.22. Read/Save/Edit/Load/Select path list to/in/from/by a saveload slot.
-------------------------------------------------------------------------------

You have to make some preparations before the usage to be able to save and
load file paths selection list in the Total Commander for a minimal steps or
mouse clicks .

-------------------------------------------------------------------------------
14.22.1. Read file selection list to a saveload slot list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\read_file_list.bat"
-from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\read_file_list.bat"
-chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\read_file_list.bat"
-to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `<list_file_name>`      - a list file name there the file paths would be
                              saved.
  * `<list_file_dir_path>`  - a list file directory path there the file paths
                              would be saved.

NOTE:
  The file name must be by the same path as in the
  `saveload_search_from_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The difference with the `save_file_list.bat` script is that the
`read_file_list.bat` script steps into each directory (not recursively) to read
the list of files from it.

-------------------------------------------------------------------------------
14.22.2. Save file selection list to a saveload slot list.
-------------------------------------------------------------------------------

For UTF-16 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\save_file_list.bat"
-from_utf16 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-16-path-list-file>"

For UTF-8 path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\save_file_list.bat"
-chcp 65001 -to_file_name "<list_file_name>" "<list_file_dir_path>" "<utf-8-wo-bom-path-list-file>"

For ANSI path list:

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\save_file_list.bat"
-to_file_name "<list_file_name>" "<list_file_dir_path>" "<ansi-path-list-file>"

Where:
  * `<list_file_name>`      - a list file name there the file paths would be
                              saved.
  * `<list_file_dir_path>`  - a list file directory path there the file paths
                              would be saved.

Note:
  The file name must be by the same path as in the
  `saveload_search_from_utf8_slot_<INDEX_STR>_SearchIn` variables in below
  section.

The `save_file_list.bat` script just saves the list of paths to a slot file as
is w/o step in into each directory.

-------------------------------------------------------------------------------
14.22.3. Edit a saveload slot list.
-------------------------------------------------------------------------------

>
"%COMMANDER_SCRIPTS_ROOT%\tacklebar\src\scripts\saveload\edit_file_list.bat"
-wait -npp -multiInst -nosession "<path-list-file>"

Where:
  * `<path_to_file_list>` - a path to list file there the file paths is stored.

-------------------------------------------------------------------------------
14.22.4. Load search from a saveload slot list.
-------------------------------------------------------------------------------

>
LOADSEARCH
saveload_search_from_utf8_slot_<INDEX>

Or

>
em_saveload_prefix_bom_and_loadsearch_from_utf16le_bom_slot_<INDEX>

Where:
  * `<INDEX_STR>`   - must be index string from `01` up to `09`.

-------------------------------------------------------------------------------
14.22.5. Load panel from a saveload slot list.
-------------------------------------------------------------------------------

>
LOADLIST
%COMMANDER_SCRIPTS_ROOT%\.saveload\file_lists\<INDEX>.utf-8.lst

Or

>
em_saveload_prefix_bom_and_loadlist_from_utf16le_bom_slot_<INDEX>

Where:
  * `<INDEX_STR>`   - must be index string from `01` up to `09`.

NOTE:
  Implemented only in the Total Commander beginning from version 10b1.

-------------------------------------------------------------------------------
14.22.6. Select panel files from a saveload slot list.
-------------------------------------------------------------------------------

>
LOADSELECTION
%COMMANDER_SCRIPTS_ROOT%\.saveload\file_lists\<INDEX>.utf-8.lst

Or

>
em_saveload_prefix_bom_and_loadselection_from_utf16le_bom_slot_<INDEX>

Where:
  * `<INDEX_STR>`   - must be index string from `01` up to `09`.

-------------------------------------------------------------------------------
15. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
15.1. Error message:
      `Windows Script Host is disabled: "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled" = 0x0`
      OR
      `Windows Script Host is disabled: "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled" = 0x0`
      OR
      Error message dialog: `Windows Script Host access is disabled on this machine, Contact your administrator for details`
-------------------------------------------------------------------------------

Reason:

  Windows Script Host is disabled to run vbs scripts.

Solution:

  Open registry editor GUI (`regedit.exe`) and find key in the windows
  registry:

    HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings
    HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings

  Set the `Enabled` parameter to `1` or remove the parameter.

-------------------------------------------------------------------------------
15.2. A Visual Basic script error message:
      `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
      OR
      A Visual Basic script hangs on execution.
-------------------------------------------------------------------------------

Reason:

  While the `_install*.bat` being ran the Windows Defender generates a false
  positive for a vbs script from the tacklelib library.

Solution:

  Turn off the Windows Defender on a moment of a script execution.

-------------------------------------------------------------------------------
15.3. A script prints error message `the script process is not properly elevated up to Administrator privileges.`
-------------------------------------------------------------------------------

Reason:

  Basically happens in the Window XP environment.
  You didn't deselect the
  `Protect my computer and data from unauthorized program activity` option
  in the `Run As` dialog.

Solution:

  Do run the script again and deselect the option in the appeared `Run As`
  dialog before press the `OK` button.

-------------------------------------------------------------------------------
15.4. A script shows an error dialog with the title and message:
      `Notepad++.exe - Entry Point Not Found`,
      `The procedure entry point GetLogicalProcessorInformation could not be located in the dynamic link library KERNEL32.dll`
-------------------------------------------------------------------------------

Reason:

  A script trying to run `Notepad++` under the Windows XP x86 SP2.
  The `Notepad++` version being distrubuted in the `tacklebar--external_tools`
  project does not support OS lower than the Windows XP x86 SP2.

Solution:

  Install Service Pack 3.

-------------------------------------------------------------------------------
15.5. A script shows GUI error dialog with the title and message:
      `notepad++.exe - Entry Point Not Found`,
      `The procedure entry point SHCreateItemFromParsingName count not be located in the dynamic link library SHELL32.dll.`
-------------------------------------------------------------------------------

Reason:

  You are trying to run Notepad++ version 7.9.3 or higher under Windows XP.
  The Notepad++ has dropped support of the Window XP beginning from the
  version 7.9.3:
  https://notepad-plus-plus.org/news/v793-released/
  https://github.com/notepad-plus-plus/notepad-plus-plus/pull/9378

Solution:

  Install the previous version of the Notepad++.

-------------------------------------------------------------------------------
15.6. A script shows an error dialog with the title and message:
      `Notepad++.exe - Unable To Locate Component`,
      `This application has failed to start because python27.dll was not found. Re-installing the application may fix this problem.`
-------------------------------------------------------------------------------

Reason:

  A script trying to run `Notepad++` with the PythonScript plugin installed.
  The PythonScript plugin trying to load `python27.dll` dynamic library and
  could not found it.

Solution:

  Manually copy the file into the root directory of the Notepad++ application.

-------------------------------------------------------------------------------
15.7. Cygwin/Msys console input stalls with the error message:
      `tee: 'standard output': Permission denied`.
-------------------------------------------------------------------------------

After run the Cygwin/Msys console from the:

  * `/src/scripts/shell/run_cygwin_bash.bat`
  * `/src/scripts/shell/run_msys_bash.bat`

The console may stalls and nothing prints until do type the `exit` command.

Reason:

  https://sourceware.org/pipermail/cygwin/2020-December/247139.html
  https://sourceware.org/pipermail/cygwin/2020-December/247185.html

  The console raster font does not have some utf-8 characters.

Solution #1:

  Manually install or switch default console font to a different font which
  has a required set of characters:

  * `Lucida Console` (True Type): builtin

  * `TerminalVector` (True Type):
     http://www.yohng.com/software/terminalvector.html
     http://www.yohng.com/files/TerminalVector.zip

  * `Terminus` (Raster):
     https://terminus-font.sourceforge.net/
     https://sourceforge.net/projects/terminus-font/files/

  * `Terminus TTF` (TrueType):
     https://files.ax86.net/terminus-ttf/#download
     https://files.ax86.net/terminus-ttf/files/latest-windows.zip

  * `Consolas` (True Type):
     https://www.microsoft.com/en-us/download/details.aspx?id=17879

  * `Hack` (True Type):
     https://github.com/source-foundry/Hack
     https://github.com/source-foundry/Hack/releases

Solution #2:

  1. Execute `_install-fonts.bat` script to install these set of fonts:

  * `TerminalVector` (True Type)
  * `Terminus` (Raster)
  * `Terminus TTF` (True Type)

  2. Manually switch default console font to installed one.

Note:
  To manually install a True Type font like `TerminalVector` and switch to it
  inside the `cmd.exe` console terminal (includes an external terminal too)
  you must:

  1. Copy the font file to the `%WINDIR%\Fonts` directory or use
     Windows Explorer context menu to install the font.
  2. Edit the registry to add a font record to the console options dialog:
     `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont`
     <Font Name> = <Font Name>
     , where <Font Name> is a truncated font name from another registry key:
     `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts`
  3. Reopen `cmd.exe` console terminal options dialog.
  4. Select the installed font in the `cmd.exe` console terminal options
     dialog.

-------------------------------------------------------------------------------
15.8. Parent `cmd.exe` console window does not hide after the open of the
      ConEmu console window GUI.
-------------------------------------------------------------------------------

Reason:

  You are using the ConEmu run mode: CONEMU_INTERACT_MODE=run

  The ConEmu run mode (`-run` switch) does not support a parent process console
  hide, so the console window would exist along with the ConEmu console window.

  The issue:

    `[Feature Request] Need a command line option to run (`-run`) together with hide a parent process console window` :
    https://github.com/Maximus5/ConEmu/issues/2240

Solution #1:

  Switch to the ConEmu attach mode: CONEMU_INTERACT_MODE=attach

-------------------------------------------------------------------------------
15.9. Parent `cmd.exe` console window does not close after the close of the
      ConEmu console window GUI.
-------------------------------------------------------------------------------

Reason:

  You are using the ConEmu run mode: CONEMU_INTERACT_MODE=run

  The ConEmu run mode (`-run` switch) does not support a parent process console
  direct close upon exit the ConEmu console not by a command close (for
  example, by `exit` command), so it leaves a parent `cmd.exe` console process
  and window as is.

Solution #1:

  Switch to the ConEmu attach mode: CONEMU_INTERACT_MODE=attach

Solution #2:

  Close the ConEmu console window by the `exit` command instead of by the
  GUI close button.

-------------------------------------------------------------------------------
15.10. Parent `cmd.exe` console process closes upon the open of the ConEmu
       console window GUI and ConEmu console window opens with wrong `cmd.exe`
       bitness instance.
       OR
       ConEmu console window prints multiple error messages:
       `The process tried to write to a nonexistent pipe.` when runs 2 or more
       console instances.
-------------------------------------------------------------------------------

Reason:

  You are using the ConEmu run mode: CONEMU_INTERACT_MODE=run
  You are using the Conemu single switch (`-single`).

  Related to the ConEmu design flaw in the run mode (`-run` switch).

  In that mode the ConEmu can not be run from more than one parent process with
  the `cmd.exe` console window. If parent process with the `cmd.exe` console
  window exists AFTER the ConEmu execution then, the ConEmu must be executed in
  detached state (without inheritance of the console handles), for example,
  through the `cmd.exe` `start`.

  The ConEmu run mode functionality can not be executed in the middle of
  `cmd.exe` process chain. The `ConEmu.exe` in the run mode must not run from
  the same process more than once, otherwise a parent process exit may happend
  upon the ConEmu detach.

  The `tacklebar` scripts uses self execution with into log redirection, which
  means they always run from different `cmd.exe` parent process, from which
  point the ConEmu run mode has a design flaw.

  This is because the ConEmu uses user level process to host the ConEmu console
  window GUI, which means it must be the only process in a whole `cmd.exe`
  inheritance tree chain (The Windows processes can not share a window GUI).

Solution #1:

  Switch to the ConEmu attach mode: CONEMU_INTERACT_MODE=attach

Solution #2:

  Execute a script in the ConEmu run mode only once.

Solution #3:

  Remove `-single` switch or use `-nosingle` switch for the ConEmu run mode.

-------------------------------------------------------------------------------
15.11. A script print error message
       `/usr/bin/bash: line 0: cd: ...: No such file or directory`
-------------------------------------------------------------------------------

Reason:

  You are using the Windows XP.

  The issue:

    This is a bug in the `Windows XP x64 SP2` and `Windows XP x86 SP3`.

Solution:

  DO NOT USE shortcut files (.lnk) in the Windows XP.
  Do use instead the `callf.exe` utility from the `contools` project.

NOTE:
  For old implementation you may use instead the `winshell_call.vbs` and
  `call.vbs` scripts from the `contools` project.

-------------------------------------------------------------------------------
15.12. A script shows GUI error dialog `Windows Script Host`:
       `Script: ...\call.vbs Line: ... Column: ... Error: Invalid procedure call or argument Code: 800A0005 Source: Microsoft VBScript runtime error`
-------------------------------------------------------------------------------

Reason:

  You are trying to call a script and only `[..]` item is selected.
  The `%WL` builtin Total Commander variable has a side effect and
  invalidates entire command line in case if only `[..]` item is selected.

Solution:

  You must select at least one existed file or directory.

  The issue was found in the Total Commander 9.51.

-------------------------------------------------------------------------------
15.13. ffmpeg prints multiple error messages while concatenating video files:
       `non-existing PPS 0 referenced`, `decode_slice_header error`
-------------------------------------------------------------------------------

Reason:

  You are trying to concatenate video files without PPS data frames.
  Read details from here:
    https://en.wikipedia.org/wiki/Network_Abstraction_Layer#Parameter_Sets

    ...
    In some applications, parameter sets may be sent within the channel that
    carries the VCL NAL units (termed "in-band" transmission). In other
    applications, it can be advantageous to convey the parameter sets
    "out-of-band" using a more reliable transport mechanism than the video
    channel itself.
    ...

Solution:

  Reacquire the video through the application which does support acquiring
  the required PPS data frames together with the main video stream.

-------------------------------------------------------------------------------
15. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
