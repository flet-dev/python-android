#!/bin/bash
set -eu

python_version=${1:?}
abi=${2:?}

# build short Python version
read python_version_major python_version_minor < <(echo $python_version | sed -E 's/^([0-9]+)\.([0-9]+).*/\1 \2/')
python_version_short=$python_version_major.$python_version_minor

# copy files to dist
mkdir -p dist/python-$python_version_short/$abi
dist_dir=$(realpath dist/python-$python_version_short/$abi)
rsync -av --exclude-from=distro.exclude install/android/$abi/python-$python_version_short/* $dist_dir

# create libpythonbundle.so
bundle_dir=$dist_dir/libpythonbundle
mkdir -p $bundle_dir

# modules with *.so files
mv $dist_dir/lib/python$python_version_short/lib-dynload $bundle_dir/modules

# site-packages
mkdir -p $bundle_dir/site-packages
echo "pip packages are installed here" > $bundle_dir/site-packages/readme.txt

# stdlib.zip
stdlib_zip=$bundle_dir/stdlib.zip
cd $dist_dir/lib/python$python_version_short
python -m compileall -b .
find . \( -name '*.so' -or -name '*.py' -or -name '*.typed' \) -type f -delete
zip -r $stdlib_zip .
cd -

# copy *.so from lib
cp $dist_dir/lib/*.so $dist_dir
rm -rf $dist_dir/lib

#tar -czf python-$python_version-android-$NDK_VERSION-$abi.tar.gz -X python/standalone.exclude -C prefix/$abi .