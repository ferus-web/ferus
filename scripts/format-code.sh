#!/usr/bin/env bash

set -e
set -o pipefail

pwd
ls

exit_val="0"

# Format the source code.
nph src || exit_val="$?"

if [[ "${exit_val}" -ne "0" ]]
  echo "format-code: nph exited with non-zero exit code $exit_val"
  echo "format-code: this workflow has failed."
  exit 1
else
  echo "format-code: nph exited with exit-code zero."
  echo "format-code: this workflow has succeeded."
  exit 0
fi
