#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLEBAR_SCRIPTS_INIT0_DIR" != "$BASH_SOURCE_DIR" ]]; then

source '/bin/bash_entry' || exit $?

TACKLEBAR_SCRIPTS_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

function __init__()
{
  # CAUTION:
  #   Here is declared ONLY a basic set of system variables required immediately in this file.
  #   All the rest system variables will be loaded from the `config.*.vars` files.
  #

  (( ! TACKLEBAR_SCRIPTS_INSTALL )) && {
    if [[ -z "$COMMANDER_SCRIPTS_ROOT" ]]; then
      echo "$0: error: COMMANDER_SCRIPTS_ROOT environment variable is not defined." >&2
      return 1
    fi

    if [[ ! -d "$COMMANDER_SCRIPTS_ROOT" ]]; then
      echo "$0: error: COMMANDER_SCRIPTS_ROOT directory does not exist: \`$COMMANDER_SCRIPTS_ROOT\`." >&2
      return 2
    fi
  }

  local MUST_LOAD_CONFIG=${1:-1}

  [[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

  tkl_normalize_path "$BASH_SOURCE_DIR/.." -a || tkl_abort_include
  tkl_export TACKLEBAR_PROJECT_ROOT                     "${RETURN_VALUE:-*:\$\{TACKLEBAR_PROJECT_ROOT\}}" # safety: replace by not applicable or unexisted directory if empty

  tkl_export TACKLEBAR_PROJECT_CONFIG_ROOT              "$TACKLEBAR_PROJECT_ROOT/_config"

  tkl_export TACKLEBAR_PROJECT_OUTPUT_ROOT              "$TACKLEBAR_PROJECT_ROOT/_out"
  tkl_export TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT       "$TACKLEBAR_PROJECT_OUTPUT_ROOT/config"

  tkl_export TACKLEBAR_PROJECT_EXTERNALS_ROOT           "$TACKLEBAR_PROJECT_ROOT/_externals"

  tkl_export CONTOOLS_ROOT                              "$TACKLEBAR_PROJECT_EXTERNALS_ROOT/contools/Scripts/Tools"

  tkl_set_error 0

  local IFS=$' \t\n'

  [[ ! -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" ]] && {
    mkdir -p "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 10
  }

  (( TACKLEBAR_SCRIPTS_INSTALL )) && {
    # explicitly generate `config.system.vars`
    [[ ! -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars" ]] && {
      cp "$TACKLEBAR_PROJECT_CONFIG_ROOT/config.system.vars.in" "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars" || tkl_abort 11
    }
  }

  if [[ -e "$TACKLEBAR_PROJECT_CONFIG_ROOT/config.system.vars.in" && -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars" ]]; then
    tkl_call_inproc_entry load_config "$TACKLEBAR_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$TACKLEBAR_PROJECT_CONFIG_ROOT" "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" "config.system.vars"
  else
    (( 0 )) # raise error level
  fi

  (( $? && MUST_LOAD_CONFIG != 0 )) && {
    echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars\` is not loaded." >&2
    tkl_abort 255
  }

  local i
  for i in PROJECT_ROOT \
    PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT \
    PROJECT_OUTPUT_ROOT PROJECT_OUTPUT_CONFIG_ROOT \
    CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      tkl_abort_include
    fi
  done

  for (( i=0; ; i++ )); do
    if [[ -e "$TACKLEBAR_PROJECT_CONFIG_ROOT/config.$i.vars.in" && -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.$i.vars" ]]; then
      tkl_call_inproc_entry load_config "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$TACKLEBAR_PROJECT_CONFIG_ROOT" "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" "config.$i.vars"
    else
      (( 0 )) # raise error level
    fi

    (( $? && MUST_LOAD_CONFIG != 0 )) && {
      echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.$i.vars\` is not loaded." >&2
      tkl_abort 255
    }

    [[ ! -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT/config.$i.vars" ]] && break
  done

  tkl_include "$TACKLEBAR_PROJECT_SCRIPTS_TOOLS_ROOT/projectlib.sh" || tkl_abort_include
}

__init__

fi
