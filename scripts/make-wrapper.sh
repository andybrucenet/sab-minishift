#!/bin/bash
# make-wrapper.sh, ABr

# local folder
g_CURDIR="$(pwd)"
g_SCRIPT_FOLDER_RELATIVE=$(dirname "$0")
cd "$g_SCRIPT_FOLDER_RELATIVE"
g_SCRIPT_FOLDER_ABSOLUTE="$(pwd)"
cd "$g_CURDIR"

# indicate we are in the correct context
MAKE_WRAPPER_INVOCATION=1
export MAKE_WRAPPER_INVOCATION

# load the environment
"$g_SCRIPT_FOLDER_ABSOLUTE"/env-wrapper.sh make "$@"

