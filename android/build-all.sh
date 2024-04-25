#!/bin/bash
set -eu

cd $(dirname $(realpath $0))

python_version="3.12.3"
export NDK_VERSION="r26d" # 26.3.11579264

read version_major version_minor < <(echo $python_version | sed -E 's/^([0-9]+)\.([0-9]+).*/\1 \2/')
version_short=$version_major.$version_minor

#for abi in armeabi-v7a arm64-v8a x86 x86_64; do
for abi in arm64-v8a; do
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
done

# Build libraries shared by all Python versions.
# ./for-each-abi.sh bzip2/build.sh 1.0.8
# ./for-each-abi.sh libffi/build.sh 3.4.4
# ./for-each-abi.sh sqlite/build.sh 2024 3450200
# ./for-each-abi.sh xz/build.sh 5.4.6

# Build all supported versions of Python, and generate `target` artifacts for Maven.
#
# For a given Python version, we can't change the OpenSSL major version after we've made
# the first release, because that would break binary compatibility with our existing
# builds of the `cryptography` package. Also, multiple OpenSSL versions can't coexist
# within the same include directory, because they use the same header file names. So we
# build each OpenSSL version immediately before all the Python versions that use it.

# ./for-each-abi.sh openssl/build.sh 1.1.1s
# python/build-and-package.sh 3.8

#./for-each-abi.sh openssl/build.sh 3.0.5
# python/build-and-package.sh 3.9
# python/build-and-package.sh 3.10
# python/build-and-package.sh 3.11
#python/build-and-package.sh 3.12
