#!/bin/bash

set -x
set -e
if [ ! "$INSTALL_HOME" ]; then
  INSTALL_HOME=$HOME/opt
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

#MAKE_FLAGS="-j 2"
if [ ! $NOBUILD_GRIDS ]; then

# compile and install metis
if [ ! $NOBUILD_METIS ]; then
mkdir -p $INSTALL_HOME
rm -rf metis-4.0
tar xzf metis-4.0.tar.gz
pushd metis-4.0
sed "s/int\ log2(int)/int\ Log2(int)/" Lib/proto.h > tmp && mv tmp  Lib/proto.h 
sed "s/int\ log2(int\ a)/int\ Log2(int\ a)/" Lib/util.c > tmp && mv tmp  Lib/util.c
for i in kmetis.c kvmetis.c mkmetis.c; do
  sed "s/log2(/Log2(/g" Lib/$i > tmp && mv tmp  Lib/$i
done
#sed "s/define\ log2/define\ Log2/g" Lib/rename.h > tmp && mv tmp  Lib/rename.h

# patch for newer  compilers
make 
popd
rm -rf $INSTALL_HOME/metis-4.0
mv metis-4.0 $INSTALL_HOME
pushd $INSTALL_HOME/metis-4.0/Graphs
#./mtest 4elt.graph
popd
fi

##
##  ALBERTA
##
if [ ! $NOBUILD_ALBERTA ] ; then
tar xzf alberta-2.0.1.tar.gz
pushd alberta-2.0.1
rm -rf $INSTALL_HOME/alberta
( ./configure CC=$CC CXX=$CXX F77=$F77 CXXFLAGS="$CXXFLAGS" CFLAGS="$CFLAGS" --without-x --enable-shared=no --with-blas-name=blas --prefix=$INSTALL_HOME/alberta && make $MAKE_FLAGS clean install ) || exit $?
popd
fi

##
## ALUGrid
##
if [ ! $NOBUILD_ALU ] ; then
tar xzf ALUGrid-1.52.tar.gz
pushd ALUGrid-1.52
rm -rf $INSTALL_HOME/alugrid
( ./configure CC=$CC CXX=$CXX F77=$F77 --prefix=$INSTALL_HOME/alugrid --with-metis=$INSTALL_HOME/metis-4.0 CPPFLAGS="$CPPFLAGS `../../dune-common*/bin/mpi-config --cflags --disable-cxx --mpicc=$MPICC`" LDFLAGS="$LDFLAGS `../../dune-common*/bin/mpi-config --libs --disable-cxx --mpicc=$MPICC`"
CXXFLAGS="$CXXFLAGS"  CFLAGS="$CFLAGS" && make $MAKE_FLAGS clean install ) || exit $?
popd
fi
fi
## UG
##
tar xzf byacc.tar.gz
#set +e
pushd byacc-20090221
make clean all
#./configure CC=$CXX CXX=$CXX F77=$F77 --prefix=$INSTALL_HOME/bison && make $MAKE_FLAGS clean install > /dev/null 2>&1    #Fails but yacc is installed
popd

tar xzf flex-2.5.35.tar.gz
pushd flex-2.5.35
./configure  --prefix $INSTALL_HOME && make install
popd
#set -e
OPATH=$PATH
export PATH=`pwd`/byacc-20090221:$INSTALL_HOME/bin:$PATH
tar xvf UG.tar.gz
pushd UG/ug
( ./autogen.sh && ./configure CC=$CXX CXX=$CXX F77=$F77 --prefix=$INSTALL_HOME/ug-install --enable-dune CXXFLAGS="$CXXFLAGS" CFLAGS="$CFLAGS" && make $MAKE_FLAGS clean install ) || exit $?
popd
export PATH=$OPATH

###
### create DUNE opts file
###
echo "# use these options for configure if no options a provided on the cmdline
CONFIGURE_FLAGS=\"--prefix=$INSTALL_HOME --disable-documentation --disable-mpiruntest --enable-parallel --enable-fieldvector-size-is-method --with-alugrid=$INSTALL_HOME/alugrid --with-alberta=$INSTALL_HOME/alberta --with-ug=$INSTALL_HOME/ug-install CXX=g++ CC=gcc CXXFLAGS=\\\"-O0 -g -Wall\\\" CFLAGS=\\\"-O0 -g -Wall\\\"\"
MAKE_FLAGS=\"all\"
" > parallel-debug.opts


###
echo "# use these options for configure if no options a provided on the cmdline
CONFIGURE_FLAGS=\"--prefix=$INSTALL_HOME --disable-documentation --disable-mpiruntest --enable-parallel --enable-fieldvector-size-is-method --with-alugrid=$INSTALL_HOME/alugrid --with-alberta=$INSTALL_HOME/alberta --with-ug=$INSTALL_HOME/ug-install CXX=g++ CC=gcc CXXFLAGS=\\\"-O3 -march=native -g0 -funroll-loops -ftree-vectorize -fno-strict-aliasing -Wall\\\" CFLAGS=\\\"-O3 -march=native -g0 -funroll-loops -ftree-vectorize -fno-strict-aliasing -Wall\\\"\"
MAKE_FLAGS=\"all\"
" > parallel.opts

# configure and build DUNE
./dune-common*/bin/dunecontrol --module=dune-pdelab-howto --opts=parallel.opts all

