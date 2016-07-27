#!/usr/bin/env bash
if [ $# -ne 2 ]; then
    echo "Usage: test_single.sh [lean-executable-path] [file]"
    exit 1
fi
ulimit -s 8192
LEAN=$1
export LEAN_PATH=../../../../library:.
f=$2
echo "-- testing $f"
if "$LEAN" "--smt2" "$f"; then
   echo "-- checked"
else
   echo "failed $f"
   exit 1
fi
