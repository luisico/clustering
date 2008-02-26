#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=cluster
dir=$plugin
tar=$plugin-v$version.tgz
files=(
pkgIndex.tcl
cluster.tcl
index.html
physbio_vmd.css
cluster1.png
cluster2.png
)

# Create a local copy of the style sheets
wget --no-verbose http://physiology.med.cornell.edu/resources/physbio.css
mv physbio.css physbio_vmd.css
cat ../vmd.css >> physbio_vmd.css
chmod 644 physbio_vmd.css

# Generate list of files
for f in ${files[@]}; do
    if [ ! -r $f ]; then
	echo "ERROR: File \"$dir/$f\" is not readable!"
	exit 11
    fi
    dirfiles="$dirfiles $dir/$f"
done

# Create distribution archive
cd ../
tar zcvf $tar $dirfiles
mv $tar $dir/versions
chmod 644 $dir/versions/$tar
cd $dir

# Clean up
rm physbio_vmd.css
