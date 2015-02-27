#!/bin/bash
if [ ! $BUILDDIR ] ; then
./dune/dune-common/bin/dunecontrol exec rm -rf debug-build
./dune/dune-common/bin/dunecontrol exec rm -rf release-build
else
./dune/dune-common/bin/dunecontrol exec rm -rf $BUILDDIR
fi
