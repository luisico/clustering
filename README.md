Clustering
=====

**Clustering** is a VMD plugin to calculate and visualize clusters of conformations for a trajectory. Each conformation is color coded according to the cluster to which it belongs. This is done by creating one representation for each cluster, and setting variable *Draw Multiple frames* to the corresponding frame numbers.

> Website: http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/clustering

Features include:

* Compute clusters using VMD's internal [measure cluster](http://www.ks.uiuc.edu/Research/vmd/current/ug/node136.html) command
* Import results from *R*, *Xcluster*, *Gromacs*, *Charmm*, *NMRCLUSTER*
* Color conformations by cluster
* Selection of clusters and/or conformations to display
* Multiple levels of clustering
* Custom representations
* Join single member clusters in a separate cluster

![Clustering Tool interface](clustering1.png?raw=true)
![Clustering Tool example](clustering2.png?raw=true)

## Installation

A small guide on how to install third party VMD plugins can be found [here](http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/installation.html). In summary:

1. Create a VMD plugins' directory if you don't have one, ie */path/to/plugins/directory*.
2. Clone or download the project into a subdirectory of your *VMD plugins' directory* (ie. */path/to/plugins/directory/clustering*):
```sh
cd /path/to/plugins/directory
git clone https://github.com/luisico/clustering.git clustering
```

3. Add the following to your *$HOME/.vmdrc* file (if you followed the instructions in the link above, you might already have the first line present):
```tcl
set auto_path [linsert $auto_path 0 {/path/to/plugins/directory}]
vmd_install_extension clustering clustering "WMC PhysBio/Clustering"
```
The plugin should be accessible from the *Extensions* menu.

## Getting started

To use the Clustering plugin you need to:

1. **Load a trajectory** of conformations used for clustering into VMD.
2. Define the **atom selection** and molecule to use as representation in vmd.
3. **Generate** the clusters with VMD's internal measure cluster command. More information about [measure cluster](http://www.ks.uiuc.edu/Research/vmd/current/ug/node136.html) can be found in VMD's manual. All options in Clustering's *Use measure cluster* section correspond to the options available to [measure cluster](http://www.ks.uiuc.edu/Research/vmd/current/ug/node136.html).
4. **Import** results from a third party solution (see below)
5. **Viewing** clusters:
  * Select the **level** you want to see. The list of clusters will be updated together with colored conformations. All clusters will be displayed when you change the level.
  * Select/Deselect **clusters** to activate/deactivate them.
  * Select/Deselect **conformations** to activate/deactivate individual conformations.
  * **All** and **None** turn on/off all clusters and conformations.
  * Activate **Join 1 member clusters** to display all single member clusters in a separate cluster (*outl*).
  * The **atom selection** to represent can be changed in the atom selection box. Click *Update Selection* button to apply the changes.

## Third party importers

### R

Ref: [R](http://www.r-project.org) with [hierarchical clustering](http://cran.r-project.org/web/views/Cluster.html)

First obtain the rmsd between structures. You can use [iTrajComp](http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp) for an easy way of doing this (I suggest writing the results in matrix format).

Load the data into R and use one of the available functions in R to do hierarchical clustering (*hclust*, *agnes*, *diana*, ...). If you used the [iTrajComp](http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp) plugin to create the rmsd matrix, the following should work in R (see the documentation of the individual commands for further options):
```R
data = scan('/path/to/rmsd.mat')
rmsd = matrix(data, nrow=sqrt(length(data)), ncol=sqrt(length(data)))
library(cluster)
cluster = agnes(rmsd, diss=T)
```

Cut the tree into groups (levels) using cutree. You can cut into one or more groupings. For example
```R
levels = cutree(cluster, k=2:5)
```
will output the cluster membership of each object for levels 2 to 5.

Write results to a file to input into the Clustering plugin:
```R
write.table(levels, file='levels.dat', quote=F)
```

Import *levels.dat* into the *Clustering*.

### Xcluster

Ref: [Xcluster](http://www.schrodinger.com)

Import Xcluster's *.clg* output file into *Clustering*. All levels of interest must be saved in order to display them in VMD (look in Xcluster's manual for the *Writecls* command).

### Gromacs

Ref: http://www.gromacs.org
g_cluster: http://manual.gromacs.org/online/g_cluster.html

Import the "cluster.log" file. Only a level (0) will be available. g_cluster timesteps are automatically mapped into VMD frames.

### Charmm

Ref: [Charmm](http://www.charmm.org) with the [clustering command](http://www.charmm.org/documentation/c35b1/correl.html#%20Cluster)

Import the *output membership* file into *Clustering*.

### NMRCLUSTER

Ref: http://neon.chem.le.ac.uk/nmrclust (link has been down for some time)

Import *Cluster.log* into *Clustering*. Only a level (0) will be available. Outliers will be splitted in different clusters. Check *Join 1 member clusters* to cluster them together.

## Author

Luis Gracia (https://github.com/luisico)

Developed at Weill Cornell Medical College

## Contributors

Please, use issues and pull requests for feedback and contributions to this project.

### Thanks

Thanks to Andrea Carotti for all his help with testing the Gromacs importer.

## License

See LICENSE.
