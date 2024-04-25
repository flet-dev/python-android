#!/bin/bash
set -eu

cd $(dirname $(realpath $0))

python_version=${1:?}
abi=${2:?}

read version_major version_minor < <(echo $python_version | sed -E 's/^([0-9]+)\.([0-9]+).*/\1 \2/')
version_short=$version_major.$version_minor

# OpenSSL build fails if lib doesn't already exist.
prefix="prefix/$abi"
mkdir -p $prefix/{bin,include,lib,share}

# build dependencies
bzip2/build.sh $prefix 1.0.8
libffi/build.sh $prefix 3.4.4
sqlite/build.sh $prefix 2024 3450200
xz/build.sh $prefix 5.4.6
openssl/build.sh $prefix 3.0.5

# cleanup before building Python
rm -r $prefix/bin

# build Python
python/build.sh $prefix $python_version

cleanup_dirs=(
    "man"
    "share"
    "lib/python$version_short/curses"
    "lib/python$version_short/idlelib"
    "lib/python$version_short/tkinter"
    "lib/python$version_short/turtle"
    "lib/python$version_short/ensurepip"
    "lib/python$version_short/pydoc_data"
)

# delete static libs
rm "prefix/$abi/lib"/{*.a,*.la}

# cleanup Python install
for dir in "${cleanup_dirs[@]}"; do
    rm -rf "prefix/$abi/$dir"
done

# delete tests
cd prefix/$abi/lib/python$version_short
find . -name test -or -name tests | xargs rm -r
find . -name __pycache__ | xargs rm -r
cd -

# zip
tar -czvf python-$python_version-android-$NDK_VERSION-$abi.tar.gz -C prefix/$abi .