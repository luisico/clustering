### Clustering routines in R (LGV'07)
library(cluster)

### cluster by rmsd
## read data and convert to a square matrix
data = scan('/home/luis/beuming/cluster/rmsd.mat')
rmsd = matrix(data, nrow=sqrt(length(data)), ncol=sqrt(length(data)))

## do the hierchical clustering with your favorite method (hclust, agnes, diana,...) to get a class twins object
cluster = agnes(rmsd, method='ward', diss=T)

## get a class hclust object for convience
cluster.h = as.hclust(cluster)

## summary and plots
summary(cluster)
plot(cluster)
pltree(cluster)

## Get the membership for different cuts: k (by number of clusters), h (by height)
levels.k1_3 = cutree(cluster, k=1:3)
write.table(levels.k1_3, file='levels.dat', quote=F)

levels.h6_5= cutree(cluster, h=6.5)

## identify clusters in the plot
plot(cluster.h)
foo1 = identify(cluster.h, N=3, MAXCLUSTER=10)
plot(cluster.h)
foo2 = rect.hclust(cluster.h, k=3)

### Using maptree
library(maptree)

## same as cutree
cluster.k3 = group.clust(cluster.h, k=3)
cluster.h6_5 = group.clust(cluster.h, h=6.5)

## table of energy for each structure. Use 2 cols: x (structure name or number) and y (energy)
energy = read.table(....)
energy = data.frame(x=seq(1,10), y=c(4,0,7,3,10,9,2,13,4,5))

## map clustering on the object vs energy plot
names(cluster.k3) = energy$x
map.groups(energy, cluster.k3)
