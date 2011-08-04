#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=cluster
dir=$plugin
tar=$plugin-v$version.tgz

files=(
pkgIndex.tcl
clustering.tcl
Makefile
doc
)

# re-arrange documentation
mkdir doc
sed -e "/html5-reset\.css/d" -e "/vmd\.css/d" index.html > doc/index.html
cp cluster1.png cluster2.png doc
cat ../html5-reset.css ../vmd.css > doc/$plugin.css
chmod -R ugo+rX doc

# Build list of files
for f in ${files[@]}; do
    if [ ! -r $f ]; then
	echo "ERROR: File \"$dir/$f\" is not readable!"
	exit 11
    fi
    dirfiles="$dirfiles $dir/$f"
done

# Compress
cd ../
tar zcvf $tar $dirfiles
mv $tar $dir/versions
chmod 644 $dir/versions/$tar
cd $dir

# Clean
rm -f physbio_vmd.css
rm -rf doc
