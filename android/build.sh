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

# zip
tar -czf python-$python_version-android-$NDK_VERSION-$abi.tar.gz -X python/standalone.exclude -C prefix/$abi .