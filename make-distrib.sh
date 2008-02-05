#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=cluster
dir=$plugin
tar=$plugin-v$version.tgz

# Compress
cd ../
tar zcvf $tar $dir/pkgIndex.tcl $dir/cluster.tcl
mv $tar $dir/versions
chmod 644 $dir/versions/$tar
cd $dir
