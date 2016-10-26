#!/bin/bash

function say {
        echo
        echo "$@"
        echo
}

function run {
        echo "$@"
        "$@"
}

function runt {
        echo "$@"
        timeout -k 4h 3h "$@"
}

set -e

#logfile="../ghcbuild.log"
#exec > >(tee "$logfile".tmp)
exec 2>&1

set -o errtrace

function failure {
        say "Failure..."
}
trap failure ERR

# We can't assume ohcount to be installed on the benchmark machine
if command -v ohcount >/dev/null 2>&1; then
  say "Code stats"

  run ohcount compiler/
  run ohcount rts/
  run ohcount testsuite/
fi

say "Installing nofib-analyse"

stack install nofib-analyse

say "Booting"

runt perl boot

say "Configuring"

echo "Try to match validate settings"
echo 'GhcHcOpts  = ' >> mk/build.mk # no -Rghc-timing
echo 'GhcLibWays := $(filter v dyn,$(GhcLibWays))' >> mk/build.mk
echo 'GhcLibHcOpts += -O -dcore-lint'  >> mk/build.mk
echo 'GhcStage2HcOpts += -O -dcore-lint'  >> mk/build.mk

runt ./configure

say "Building"

runt /usr/bin/time make -j2 V=0

say "Running the testsuite"

run make -C testsuite fast VERBOSE=4 THREADS=2

say "Running nofib"

runt make -C nofib boot
runt make -C nofib NoFibRuns=15

say "Total space used"

run du -sc .
