#!/bin/bash
if [ ! $BUILDDIR ] ; then
BUILDDIR=build-cmake
fi

./dune/dune-common/bin/dunecontrol exec rm -rf $BUILDDIR
