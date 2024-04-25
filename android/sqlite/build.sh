#!/bin/bash
set -eu

recipe_dir=$(dirname $(realpath $0))
prefix=$(realpath ${1:?})

# We pass in the version in the same format as the URL. For example, version 3.39.2
# becomes 3390200.
year=${2:?}
version=${3:?}

cd $recipe_dir
. ../build-common.sh

version_dir=$recipe_dir/build/$version
mkdir -p $version_dir
cd $version_dir
src_filename=sqlite-autoconf-$version.tar.gz
wget -c https://www.sqlite.org/$year/$src_filename

build_dir=$version_dir/$abi
rm -rf $build_dir
mkdir $build_dir
cd $build_dir
tar -xf $version_dir/$src_filename
cd $(basename $src_filename .tar.gz)

patch -p1 -i $recipe_dir/strerror_r.patch

CFLAGS+=" -Os"  # This is off by default, but it's recommended in the README.
./configure --host=$host_triplet --disable-static --disable-static-shell --with-pic
make -j $(nproc)
make install prefix=$prefix