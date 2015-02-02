#!/bin/bash

# Convenience shell script to build an exercise. By default, all
# present dune modules (core modules and exercise modules) are built.
#
# You can customize the beahviour by setting the following environment variables:
# OPTS : the opts file to use, defaults to the generated ../config.opts
# MODULE : only build the given module and all its dependencies
# ONLY : only build the given module. Only works with prebuilt dependent modules
#
# Example usage:
# ONLY=pdelab-exercise3 ./build_exercises.sh
#
# To get rid of this script, read dune-common/bin/dunecontrol --help

if [ ! $OPTS ] ; then
OPTS="config.opts"
fi

if [ $MODULE ] ; then
MODSTRING="--module=$MODULE"
fi

if [ $ONLY ] ; then
MODSTRING="--only=$ONLY"
fi

./dune/dune-common/bin/dunecontrol $MODSTRING --use-cmake --opts=$OPTS all
