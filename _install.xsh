import os, sys, argparse

if not hasattr(globals(), 'tkl_init'):
  # portable import to the global space
  sys.path.append(os.environ['TACKLELIB_PYTHON_SCRIPTS_ROOT'])
  import tacklelib as tkl

  tkl.tkl_init(tkl, global_config = {'log_import_module':os.environ.get('TACKLELIB_LOG_IMPORT_MODULE')})

  # cleanup
  del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
  sys.path.pop()

# basic initialization, loads `config.private.yaml`
tkl_source_module(SOURCE_DIR, '__init__/__init__.xsh')

tkl_import_module(CMDOPLIB_PYTHON_SCRIPTS_ROOT, 'cmdoplib.svn.xsh', 'cmdoplib_svn')
tkl_import_module(CMDOPLIB_PYTHON_SCRIPTS_ROOT, 'cmdoplib.gitsvn.xsh', 'cmdoplib_gitsvn')
