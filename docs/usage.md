Usage:
    apparmorize install [ -p PROF ] [ -s DIR ] [ -n NUM ] [ -g ]
    apparmorize remove  [ -s DIR ] [ -g ]
    apparmorize run PROGRAM [ -s DIR ]
    apparmorize -h | --help 

Options:
    -p, --profile PROF      Use a different profile (default standard)
    -s, --spool DIR         Spool directory where programs are run.
    -n, --number NUM        Number of simultaneous profiles
    -g, --go                Execute, otherwise dry-run


