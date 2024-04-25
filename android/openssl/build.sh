#!/bin/bash
set -eu

recipe_dir=$(dirname $(realpath $0))
prefix=$(realpath ${1:?})
version=${2:?}

cd $recipe_dir
. ../build-common.sh

version_dir=$recipe_dir/build/$version
mkdir -p $version_dir
cd $version_dir
src_filename=openssl-$version.tar.gz
wget -c https://www.openssl.org/source/$src_filename

build_dir=$version_dir/$abi
rm -rf $build_dir
mkdir $build_dir
cd $build_dir
tar -xf $version_dir/$src_filename
cd $(basename $src_filename .tar.gz)

patch -p1 -i $recipe_dir/at_secure.patch

# CFLAGS environment variable replaces default flags rather than adding to them.
CFLAGS+=" -O2"
export LDLIBS="-latomic"

if [[ $abi =~ '64' ]]; then
    bits="64"
else
    bits="32"
fi
./Configure linux-generic$bits shared
make -j $(nproc)

install_dir="/tmp/openssl-install-$$"
rm -rf $install_dir
make install_sw DESTDIR=$install_dir
tmp_prefix="$install_dir/usr/local"
rm -rf $prefix/include/openssl
cp -af $tmp_prefix/include/* $prefix/include
rm -rf $prefix/lib/lib{crypto,ssl}*.so*
cp -af $tmp_prefix/lib/*.{so*,a} $prefix/lib
rm -r $install_dir