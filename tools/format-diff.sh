#!/usr/bin/env bash

function panic() {
    echo $@ >&2
    exit 1
}

# require binary version_idx min_version
function require() {
    which $1 &> /dev/null || panic $1 is required to run this script.
    if [[ $# -eq 1 ]]; then
        return 0
    fi
    version=`$1 --version | cut -d ' ' -f $2`
    min_version=`printf "$3\n$version" | sort -V | head -n 1`
    [[ "$min_version" == $3 ]] || panic version of $1 should be larger than $3
}

require git 3 1.7.8
require python
require rustfmt 1 0.8.3
require grep

extract_script=`dirname "$0"`/extract-diff.py

if git diff --quiet -- '*.rs'; then
    base=`git merge-base master HEAD`
    if git diff --quiet $base -- '*.rs'; then
        exit 0
    fi
else
    base=HEAD
fi

rustfmt=`which rustfmt`

python "$extract_script" $base $rustfmt --write-mode diff | grep -E "Diff .*at line" > /dev/null

exit_status=(${PIPESTATUS[@]})
if [[ ${exit_status[0]} -ne 0 ]]; then
    exit ${exit_status[0]}
elif [[ ${exit_status[1]} -eq 0 ]]; then
    # only format diff when we need to.
    python "$extract_script" $base $rustfmt --write-mode overwrite
fi
