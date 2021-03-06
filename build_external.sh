#!/bin/bash

# This script is used as a one touch build system for the Dune course 2015
# held at IWR, University of Heidelberg. For more general documentation on
# how to configure and install Dune, check www.dune-project.org

# You can configure this script by setting the following environment variables:
# See brackets for defaults.
#
# INSTALL_HOME the directory to install external packages in ($HOME/external)
# F77 the fortran compiler (gfortran)
# CC the C compiler (gcc)
# MPICC the MPI compiler (mpicc)
# CXX the C++ compiler (g++)
# CXXFLAGS the standard C++ flags for external libraries ("-O3 -DNEBUG")
# CFLAGS the standard C flags for external libraries (copy CXXFLAGS)
# MAKE_FLAGS flags to be given to make during the build process ("-j2")
#
# You can disable some parts of this script by setting the variables NOBUILD_<part>,
# where part is out of METIS, ALBERTA, ALU, UG, GRIDS (which is equivalent to the
# former four) or DUNE (which disables the call to the build_exercise.sh script).


# set the proper defaults for variables which may be set from the outside.
set -x
set -e
ROOT=$(pwd)
if [ ! "$INSTALL_HOME" ]; then
  INSTALL_HOME=$ROOT/external
fi
if [ ! "$F77" ]; then
  F77=gfortran
fi
if [ ! "$CC" ]; then
CC=gcc
fi
if [ ! "$MPICC" ]; then
MPICC=mpicc
fi
if [ ! "$CXX" ]; then
CXX=g++
fi
if [ ! "$CXXFLAGS" ]; then
CXXFLAGS="-O3 -DNDEBUG"
fi
CFLAGS="$CXXFLAGS"
if [ ! "$MAKE_FLAGS" ]; then
MAKE_FLAGS="-j2"
fi

#if [ ! $NOBUILD_SUPERLU ]; then
#pushd $INSTALL_HOME
#mkdir -p superlu
#pushd superlu
#mkdir -p lib
#mkdir -p include
#popd
#pushd tarballs
#rm -rf SuperLU_4.3
#tar xzf ./superlu-4.3.tar.gz
#pushd SuperLU_4.3
#(
#cp MAKE_INC/make.linux make.inc
#sed -i "s|\$(HOME)/Codes/SuperLU_4.3|$INSTALL_HOME/superlu|g" make.inc
#make $MAKE_FLAGS all
#chmod 444 ./SRC/*.h
#cp ./SRC/*.h $INSTALL_HOME/superlu/include
#popd
#rm -rf SuperLU_4.3
#) || exit $?
#popd
#popd
#popd
#fi

if [ ! $NOBUILD_GRIDS ]; then

## compile and install metis
if [ ! $NOBUILD_METIS ]; then
pushd $INSTALL_HOME
pushd tarballs
rm -rf metis-5.1.0
tar xzf ./metis-5.1.0.tar.gz
pushd metis-5.1.0
(make config prefix=$INSTALL_HOME/metis && make $MAKE_FLAGS && make install) || exit $?
popd
rm -rf metis-5.1.0
popd
popd
fi

## compile and install alberta 3
if [ ! $NOBUILD_ALBERTA ] ; then
pushd $INSTALL_HOME
pushd tarballs
rm -rf alberta-3.0.1
tar xzf alberta-3.0.1.tar.gz
pushd alberta-3.0.1
( ./configure CC=$CC CXX=$CXX F77=$F77 CXXFLAGS="$CXXFLAGS" CFLAGS="$CFLAGS" --without-x --enable-shared=no --with-blas-name=blas --prefix=$INSTALL_HOME/alberta --disable-fem-toolbox && make $MAKE_FLAGS install ) || exit $?
popd
rm -rf alberta-3.0.1
popd
popd
fi

## compile and install ALUGrid 1.52
if [ ! $NOBUILD_ALU ] ; then
pushd $INSTALL_HOME
pushd tarballs
rm -rf ALUGrid-1.52
tar xzf ALUGrid-1.52.tar.gz
pushd ALUGrid-1.52
( ./configure CC=$CC CXX=$CXX F77=$F77 --prefix=$INSTALL_HOME/alugrid --with-metis=$INSTALL_HOME/metis CPPFLAGS="$CPPFLAGS `../../dune-common*/bin/mpi-config --cflags --disable-cxx --mpicc=$MPICC`" LDFLAGS="$LDFLAGS `../../dune-common*/bin/mpi-config --libs --disable-cxx --mpicc=$MPICC`"
CXXFLAGS="$CXXFLAGS"  CFLAGS="$CFLAGS" && make $MAKE_FLAGS install ) || exit $?
popd
rm -rf ALUGrid-1.52
popd
popd
fi

## compile and install UG 3.11
if [ ! $NOBUILD_UG ] ; then
pushd $INSTALL_HOME
pushd tarballs
rm -rf ug-3.11.0
tar xzf ug-3.11.0.tar.gz
pushd ug-3.11.0
( ./configure MPICC=$MPICC CC=$CXX --prefix=$INSTALL_HOME/ug CXXFLAGS="$CXXFLAGS" --enable-parallel --enable-dune && make $MAKE_FLAGS && make install ) || exit $?
popd
rm -rf ug-3.11.0
popd
popd
fi

fi

CC=$(which $CC)
CXX=$(which $CXX)

# generate an opts file with release flags
echo "CMAKE_FLAGS=\"
-DALBERTA_ROOT=$INSTALL_HOME/alberta
-DALUGRID_ROOT=$INSTALL_HOME/alugrid
-DMETIS_ROOT=$INSTALL_HOME/metis
-DUG_ROOT=$INSTALL_HOME/ug
-DCMAKE_C_COMPILER='$CC'
-DCMAKE_CXX_COMPILER='$CXX'
-DCMAKE_CXX_FLAGS_RELEASE='-O3 -DNDEBUG -g0 -Wno-deprecated-declarations -funroll-loops'
-DCMAKE_BUILD_TYPE=Release
\"" > release.opts

# generate an opts file with debug flags
echo "CMAKE_FLAGS=\"
-DALBERTA_ROOT=$INSTALL_HOME/alberta
-DALUGRID_ROOT=$INSTALL_HOME/alugrid
-DMETIS_ROOT=$INSTALL_HOME/metis
-DUG_ROOT=$INSTALL_HOME/ug
-DCMAKE_C_COMPILER='$CC'
-DCMAKE_CXX_COMPILER='$CXX'
-DCMAKE_CXX_FLAGS_DEBUG='-O0 -ggdb -Wall'
-DCMAKE_BUILD_TYPE=Debug
\"" > debug.opts

# now download all the dune modules and all exercise modules
git submodule init
git submodule update

# make the other scripts provided by this module exectuable
chmod +x build_exercise.sh
chmod +x cleanup.sh

if [ ! $NOBUILD_DUNE ] ; then
./build_exercise.sh
fi
