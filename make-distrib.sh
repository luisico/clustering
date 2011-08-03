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

# Create a local copy of the style sheets
wget --no-verbose http://physiology.med.cornell.edu/resources/physbio.css
mv physbio.css physbio_vmd.css
cat ../vmd.css >> physbio_vmd.css
chmod 644 physbio_vmd.css

# re-arrange documentation
mkdir doc
cp index.html cluster1.png cluster2.png physbio_vmd.css doc
wget -q -O doc/vmdbackup.css http://physiology.med.cornell.edu/resources/physbio.css http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/vmd.css
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
