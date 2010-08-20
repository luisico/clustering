#
#              Clustering Tool v1.7
#
# A clustering tool to represent clusters in VMD.
#
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/cluster

# Author
# ------
#   Luis Gracia, PhD
#
#      Scientific Software Specialist
#      Department of Physiology & Biophysics
#      Weill Cornell Medical College 
#      1300 York Avenue, Rm LC-501F
#      New York, NY 10065
#
#   lug2002@med.cornell.edu

# Documentation
# -------------
# See the index.html file distributed with this file. For more update documentation see
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/cluster

## $Id$

# ToDo:
# - control clusters of different molecules:
#   - add a dimension to array cluster.
#   - change in molecule, switches to the cluster.
#   - delete data of a molecule if a molecule no longer exists.
# - better parse on import to remove extra blanks

package provide clustering 2.0

namespace eval ::clustering:: {
  namespace export clustering
}

# Hook for vmd, start the GUI
proc clustering_tk_cb {} {
  clustering::cluster
  return $clustering::w
}

proc clustering::destroy {} {
  # Delete traces
  # Delete remaining selections

  global vmd_initialize_structure
  trace vdelete vmd_initialize_structure w [namespace code UpdateMolecules]
}

# Main window
proc clustering::cluster {} {
  variable w;   # TK window

  variable webpage "http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/cluster"
  variable cluster;          # Array with all levels clustering (set on import)
  variable cluster0;         # Array with current selected level
  variable clust_file;       # File used to load clustering data
  variable clust_mol;        # Molecule use to show clustering
  variable clust_list;       # Listbox with clusters for selected level
  variable level_list;       # Listbox with available clustering levels
  variable conf_list;        # Listbox with conformations for a level
  variable join_1members  1; # Join single member clusters in a separate cluster
  variable bb_def  "C CA N"; # Backbone definition (diferent from VMD's definition)
  variable bb_only        0; # Selection modifier (only name CA C N)
  variable trace_only     0; # Selection modifier (only name CA)
  variable noh            1; # Selection modifier (no hydrogens)
  variable calc_nclusters 5; # Calculation options (number of clusters)
  variable calc_cutoff  1.0; # Calculation options (cutoff)
  variable calc_first     0; # Calculation options (first frame)
  variable calc_last     -1; # Calculation options (last frame)
  variable calc_step      1; # Calculation options (frame step)
  global vmd_initialize_structure

  if {[molinfo num] > 0} {
    set clust_mol [molinfo top get id]
  }

  # If already initialized, just turn on
  if { [winfo exists .clustering] } {
    wm deiconify $w
    return
  }

   # GUI look
  option add *clustering.*borderWidth 1
  option add *clustering.*Button.padY 0
  option add *clustering.*Menubutton.padY 0

  # Main window
  set w [toplevel ".clustering"]
  wm title $w "Clustering Tool"
  wm resizable $w 1 1
  bind $w <Destroy> [namespace current]::destroy

  # Menu
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -fill x

  # Import menu
  menubutton $w.menubar.import -text "Import" -underline 0 -menu $w.menubar.import.menu
  pack $w.menubar.import -side left
  menu $w.menubar.import.menu -tearoff no
  $w.menubar.import.menu add command -label "NMRcluster..."          -command "[namespace current]::import nmrcluster"
  $w.menubar.import.menu add command -label "Xcluster..."            -command "[namespace current]::import xcluster"
  $w.menubar.import.menu add command -label "Cutree (R)..."          -command "[namespace current]::import cutree"
  $w.menubar.import.menu add command -label "Gromacs (g_cluster)..." -command "[namespace current]::import gcluster"
  $w.menubar.import.menu add command -label "Charmm..." -command "[namespace current]::import charmm"

  # Menubar / Help menu
  menubutton $w.menubar.help -text "Help" -menu $w.menubar.help.menu
  pack $w.menubar.help -side right
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "Help" -command "vmd_open_url $webpage"
  $w.menubar.help.menu add command -label "About" -command [namespace current]::about
  

  # Selection frame
  frame $w.sel -relief ridge
  pack $w.sel -side top -fill x

  # Selection
  frame $w.sel.left
  pack $w.sel.left -side left -fill both -expand yes
  
  text $w.sel.left.sel -height 3 -width 25 -highlightthickness 0 -selectborderwidth 0 -exportselection yes -wrap word -relief sunken -bd 1
  pack $w.sel.left.sel -side top -fill both -expand yes
  $w.sel.left.sel insert end "protein"

  # Selections options
  frame $w.sel.right
  pack $w.sel.right -side right

  checkbutton $w.sel.right.bb -text "Backbone" -variable [namespace current]::bb_only -command "[namespace current]::ctrlbb bb"
  checkbutton $w.sel.right.tr -text "Trace" -variable [namespace current]::trace_only -command "[namespace current]::ctrlbb trace"
  checkbutton $w.sel.right.noh -text "noh" -variable [namespace current]::noh -command "[namespace current]::ctrlbb noh"
  pack $w.sel.right.bb $w.sel.right.tr $w.sel.right.noh -side top -anchor nw

  # Calculate
  frame $w.calc
  pack $w.calc -side top -fill x -anchor nw

  frame $w.calc.buttons
  pack $w.calc.buttons -side left -anchor nw

  button $w.calc.buttons.cluster -text "Cluster" -command [namespace code calculate]
  pack $w.calc.buttons.cluster -side top -anchor nw

  button $w.calc.buttons.update -text "Views" -command [namespace code UpdateSel]
  pack $w.calc.buttons.update -side top -anchor nw

  frame $w.calc.options
  pack $w.calc.options -side left -anchor nw

  frame $w.calc.options.1
  pack $w.calc.options.1 -side top -anchor nw

  frame $w.calc.options.1.mol
  pack $w.calc.options.1.mol -side left -anchor nw

  label $w.calc.options.1.mol.label -text "Mol:"
  menubutton $w.calc.options.1.mol.value -relief raised -bd 2 -direction flush \
    -textvariable [namespace current]::clust_mol -menu $w.calc.options.1.mol.value.menu
  menu $w.calc.options.1.mol.value.menu
  pack  $w.calc.options.1.mol.label $w.calc.options.1.mol.value -side left

  frame $w.calc.options.1.ncluster
  pack $w.calc.options.1.ncluster -side left -anchor nw
  label $w.calc.options.1.ncluster.label -text "N clusters:"
  entry $w.calc.options.1.ncluster.value -width 3 -textvariable [namespace current]::calc_nclusters
  pack $w.calc.options.1.ncluster.label $w.calc.options.1.ncluster.value -side left -anchor nw

  frame $w.calc.options.1.cutoff
  pack $w.calc.options.1.cutoff -side left -anchor nw
  label $w.calc.options.1.cutoff.label -text "Cutoff:"
  entry $w.calc.options.1.cutoff.value -width 5 -textvariable [namespace current]::calc_cutoff
  pack $w.calc.options.1.cutoff.label $w.calc.options.1.cutoff.value -side left -anchor nw

  frame $w.calc.options.2
  pack $w.calc.options.2 -side top -anchor nw

  frame $w.calc.options.2.first
  pack $w.calc.options.2.first -side left -anchor nw
  label $w.calc.options.2.first.label -text "First:"
  entry $w.calc.options.2.first.value -width 4 -textvariable [namespace current]::calc_first
  pack $w.calc.options.2.first.label $w.calc.options.2.first.value -side left -anchor nw

  frame $w.calc.options.2.last
  pack $w.calc.options.2.last -side left -anchor nw
  label $w.calc.options.2.last.label -text "Last:"
  entry $w.calc.options.2.last.value -width 4 -textvariable [namespace current]::calc_last
  pack $w.calc.options.2.last.label $w.calc.options.2.last.value -side left -anchor nw

  frame $w.calc.options.2.step
  pack $w.calc.options.2.step -side left -anchor nw
  label $w.calc.options.2.step.label -text "Step:"
  entry $w.calc.options.2.step.value -width 4 -textvariable [namespace current]::calc_step
  pack $w.calc.options.2.step.label $w.calc.options.2.step.value -side left -anchor nw


  # Data
  frame $w.data -relief ridge -bd 2

  # Data / Level
  frame $w.data.level
  label $w.data.level.label -text "Levels:"
  pack  $w.data.level.label -side top
  set level_list [listbox $w.data.level.listbox -selectmode single -activestyle dotbox -width 3 -exportselection 0 -yscroll [namespace code {$w.data.level.scroll set}] ]
  pack  $level_list -side left -fill both -expand 1
  scrollbar $w.data.level.scroll -command [namespace code {$level_list yview}]
  pack  $w.data.level.scroll -side left -fill y -expand 1
  bind $level_list <<ListboxSelect>> [namespace code UpdateLevels]
  pack $w.data.level -side left -fill both -expand 1

  # Data / cluster
  frame $w.data.cluster
  label $w.data.cluster.label -text "Clusters:"
  pack  $w.data.cluster.label -side top
  set clust_list [listbox $w.data.cluster.listbox -selectmode multiple -activestyle dotbox -width 3 -exportselection 0 -yscroll [namespace code {$w.data.cluster.scroll set}] ]
  pack  $clust_list -side left -fill both -expand 1
  scrollbar $w.data.cluster.scroll -command [namespace code {$clust_list yview}]
  pack  $w.data.cluster.scroll -side left -fill y -expand 1
  bind $clust_list <<ListboxSelect>> [namespace code UpdateClusters]
  pack $w.data.cluster -side left -fill both -expand 1

  # Data / buttons
  frame $w.data.buttons
  button $w.data.buttons.all -text "All" -command [namespace code {clus_onoff_all 1}]
  pack $w.data.buttons.all -side top
  button $w.data.buttons.none -text "None" -command [namespace code {clus_onoff_all 0}]
  pack $w.data.buttons.none -side top
  pack $w.data.buttons -side left

  # Data / confs
  frame $w.data.confs
  label $w.data.confs.label -text "Confs:"
  pack  $w.data.confs.label -side top
  set conf_list [listbox $w.data.confs.listbox -selectmode multiple -activestyle dotbox -width 3 -exportselection 0 -yscroll [namespace code {$w.data.confs.scroll set}] ]
  pack $conf_list -side left -fill both -expand 1
  scrollbar $w.data.confs.scroll -command [namespace code {$conf_list yview}]
  pack  $w.data.confs.scroll -side left -fill y -expand 1
  pack $w.data.confs -side left -fill both -expand 1
  bind $conf_list <<ListboxSelect>> [namespace code UpdateConfs]

  pack $w.data -fill both -expand 1

  # Options
  frame $w.options -relief ridge -bd 2
  pack $w.options -fill y -anchor nw

  # Options / join 1 member clusters
  frame $w.options.join
  checkbutton $w.options.join.cb -text "Join 1 member clusters" -variable clustering::join_1members -command [namespace code UpdateLevels]
  pack $w.options.join.cb -side top -anchor nw
  pack $w.options.join -side top -anchor nw


  # Status
  frame $w.status -relief raised -bd 1
  pack $w.status -fill x

  label $w.status.clustfile_label -text "Cluster:"
  pack  $w.status.clustfile_label -side left
  entry $w.status.clustfile_entry -textvariable clustering::clust_file
  pack  $w.status.clustfile_entry -side left -fill x -expand 1

  # Set up the molecule list
  trace variable vmd_initialize_structure w [namespace current]::UpdateMolecules
  [namespace current]::UpdateMolecules
}
  

#############################################################################
# Update GUI

# Update GUI with selected level
proc clustering::UpdateLevels {} {
  variable level_list
  variable clust_list
  variable conf_list
  variable clust_mol
  variable cluster
  variable cluster0
  variable join_1members
  variable colors
  variable color

  # Reset
  $clust_list delete 0 end
  $conf_list delete 0 end
  if {[info exists colors]} {
    unset colors
  }
  set color -1
  [namespace current]::del_reps $clust_mol

  # Copy cluster/level to cluster0
  set level [$level_list get [$level_list curselection]]
  if {[array exists cluster0]} {unset cluster0}
  foreach key [array names cluster $level:*] {
    regsub "$level:" $key {} name
    set cluster0($name) $cluster($key)
  }
  
  # Join 1 members if requested
  if {$join_1members} {
    [namespace current]::join_1members
  }

  set nclusters [array size cluster0]
  set names [lsort -dictionary [array names cluster0]]
  #puts "DEBUG: nclusters= $nclusters; names $names"

  # Find number of conformations
  set nconfs 0
  foreach key [array names cluster0] {
    set nconfs [expr {$nconfs + [llength $cluster0($key)]}]
  }
  #puts "DEBUG: nconfs $nconfs"
  
  # Populate list of conformations
  for {set i 0} {$i < $nconfs} {incr i} {
    $conf_list insert end $i
  }

  # Populate list of clusters and add representations
  for {set i 1} {$i <= $nclusters} {incr i} {
    regsub "$level:" [lindex $names [expr {$i-1}]] {} name
    [namespace current]::populate $i $name
    [namespace current]::add_rep $i $name
  }

  $clust_list selection set 0 [expr {$nclusters-1}]
  $conf_list selection set 0 end
  if {[$clust_list get [expr {$nclusters-1}]] == "outl"} {
    [namespace current]::clus_onoff 0 [expr {$nclusters-1}]
  }
}

# Populate cluster listbox
proc clustering::populate {num name} {
  variable clust_list
  variable conf_list
  variable cluster0

  #puts "DEBUG: populate cluster $num ($name)"

  # Choose color
  set col [[namespace current]::next_color]
  set rgb [index2rgb $col]

  # Add clusters to list and change conformation color
  $clust_list insert end $name
  $clust_list itemconfigure [expr {$num-1}] -selectbackground $rgb
  foreach conf $cluster0($name) {
    $conf_list itemconfigure $conf -selectbackground $rgb
  }
}

# Update clusters
proc clustering::UpdateClusters {} {
  variable clust_list
  variable cluster0

  for {set i 0} {$i < [array size cluster0]} {incr i} {
    if {[$clust_list selection includes $i]} {
      [namespace current]::clus_onoff 1 $i
    } else {
      [namespace current]::clus_onoff 0 $i
    }
  }
}

# Update conformations
proc clustering::UpdateConfs {} {
  variable clust_mol
  variable conf_list
  variable cluster0
  variable clust_list

  # Create reverse list of clusters beloging to confs
  for {set c 0} {$c < [array size cluster0]} {incr c 1} {
    set name [$clust_list get $c]
    foreach f $cluster0($name) {
      set confs($f) $c
    }
  }

  # Create list of selected confs
  for {set i 0} {$i < [$conf_list size]} {incr i} {
    if {[$conf_list selection includes $i]} {
      lappend on $i
    }
  }
  
  # create new cluster
  if {![info exists on]} {
    for {set c 0} {$c < [array size cluster0]} {incr c} {
      $clust_list selection clear $c
      mol showrep $clust_mol $c off
    }
    return
  }
  foreach f $on {
    lappend frames($confs($f)) $f
  }

  # apply changes
  set names [array names frames]
  for {set c 0} {$c < [array size cluster0]} {incr c} {
    if {[lsearch -exact $names $c] == -1} {
      $clust_list selection clear $c
      mol showrep $clust_mol $c off
    } else {
      if {[$clust_list selection includes $c] == 0} {
	$clust_list selection set $c
	mol showrep $clust_mol $c on
      }
      mol drawframes $clust_mol $c $frames($c)
    }
  }
}

# Update list of molecules
proc clustering::UpdateMolecules {args} {
  # Code adapted from the ramaplot plugin
  variable w
  variable clust_mol
  
  set mollist [molinfo list]

  # Update the molecule browser
  $w.calc.options.1.mol.value.menu delete 0 end
  $w.calc.options.1.mol.value configure -state disabled
  if { [llength $mollist] != 0 } {
    foreach id $mollist {
      if {[molinfo $id get filetype] != "graphics"} {
        $w.calc.options.1.mol.value configure -state normal 
        $w.calc.options.1.mol.value.menu add radiobutton -value $id \
	  -label "$id [molinfo $id get name]" -variable [namespace current]::clust_mol
      }
    }
  }
}

# Update representations with atomselection
proc clustering::UpdateSel {} {
  variable cluster0
  variable clust_mol

  for {set i 0} {$i < [array size cluster0]} {incr i} {
      mol modselect $i $clust_mol [[namespace current]::set_sel]
  }
}


#############################################################################
# Clusters/Conformations and representations

# Add rep for a cluster
proc clustering::add_rep {num name} {
  variable cluster0
  variable clust_mol
  variable clust_list
  variable colors

  foreach f $cluster0($name) {
    lappend frames $f
  }

  mol rep lines
  mol selection [[namespace current]::set_sel]
  mol addrep $clust_mol
  mol drawframes $clust_mol [expr {$num-1}] $frames
  set col [lindex $colors [expr {$num-1}]]
  mol modcolor [expr {$num-1}] $clust_mol ColorID $col
}

# Delete all reps
proc clustering::del_reps {clust_mol} {
  set numreps [molinfo $clust_mol get numreps]
  for {set f 0} {$f <= $numreps} {incr f 1} {
    mol delrep 0 $clust_mol
  }
}

# Set on/off one or more clusters
proc clustering::clus_onoff_all {state} {
  variable cluster0

  for {set c 0} {$c < [array size cluster0]} {incr c 1} {
    [namespace current]::clus_onoff $state $c
  }
}

# Set on/off a cluster
proc clustering::clus_onoff {state clus} {
  variable clust_mol
  variable cluster0
  variable clust_list
  variable conf_list
  variable w

  set name [$clust_list get $clus]
  #puts "DEBUG: cluster $clus name $name"

  if { $state == 0 } {
    $clust_list selection clear $clus
  } else {
    $clust_list selection set $clus
  }

  set this $cluster0($name)

  if { $state == 0 } {
    foreach f $this {
      $conf_list selection clear $f
    }
    mol showrep $clust_mol $clus off
  } else {
    foreach f $this {
      $conf_list selection set $f
      lappend frames $f
    }
    mol drawframes $clust_mol $clus $frames
    mol showrep $clust_mol $clus on
  }
}

# Set on one or more clusters
proc clustering::clus_on {clus} {
  [namespace current]::clus_onoff 1 $clus
}

# Set off one or more clusters
proc clustering::clus_off {clus} {
  [namespace current]::clus_onoff 0 $clus
}


#############################################################################
# Other

# Select next available color
proc clustering::next_color {} {
  variable colors
  variable color

  incr color
  #puts "Color $color [lindex [colorinfo colors] $color]"

  # Avoid same color as VMD background
  if {[colorinfo index [colorinfo category Display Background]] == $color} {
    incr color
    #puts "     ...same as bg ... switch to $color"
  }

  # Recycle colors
  if {$color > [colorinfo num]} {
    set color 0
    #puts "     ...over max ... switch to $color"
  }
  #puts "DEBUG: color $color"
  lappend colors $color
  return $color
}

# Convert a VMD color index to rgb
proc clustering::index2rgb {i} {
  set len 2
  lassign [colorinfo rgb $i] r g b
  set r [expr {int($r*255)}]
  set g [expr {int($g*255)}]
  set b [expr {int($b*255)}]
  #puts "$i      $r $g $b"
  return [format "#%.${len}X%.${len}X%.${len}X" $r $g $b]
}

# Parse selection
proc clustering::set_sel {} {
  variable w
  variable bb_only
  variable trace_only
  variable noh
  variable bb_def

  regsub -all "\#.*?\n" [$w.sel.left.sel get 1.0 end] "" temp1
  regsub -all "\n" $temp1 " " temp2
  regsub -all " $" $temp2 "" temp3
  if { $trace_only } {
    append sel "($temp3) and name CA"
  } elseif { $bb_only } {
    append sel "($temp3) and name $bb_def"
  } elseif { $noh} {
    append sel "($temp3) and noh"
  } else {
    append sel $temp3
  }
  return $sel
}

# Join single member clusters in a separate cluster
proc clustering::join_1members {} {
  variable cluster0

  foreach name [array names cluster0] {
    #puts "$name - $cluster0($name)"
    if {[llength $cluster0($name)] == 1} {
      if [info exists cluster0(outl)] {
	set cluster0(outl) [concat $cluster0(outl) $cluster0($name)]
      } else {
	set cluster0(outl) $cluster0($name)
      }
      unset cluster0($name)
    }
  }
}

# Decrease all members of a list by 1
proc clustering::decrease_list {data} {
  for {set i 0} {$i < [llength $data]} {incr i} {
    lset data $i [expr {[lindex $data $i] - 1}]
  }
  return $data
}

# Control selection modifiers
proc clustering::ctrlbb { obj } {
  variable w
  variable bb_only
  variable trace_only
  variable noh

  if {$obj == "bb"} {
    set trace_only 0
    set noh 0
  } elseif {$obj == "trace"} {
    set bb_only 0
    set noh 0
  } elseif {$obj == "noh"} {
    set trace_only 0
    set bb_only 0
  }
}

# About
proc clustering::about { {parent .clustering} } {
  variable webpage
  set vn [package present clustering]
  tk_messageBox -title "About Clustering v$vn" -parent $parent -message \
"Clustering v$vn

Cluster is a VMD plugin to visualize clusters of conformations of a structure.

More information at:
$webpage

Copyright (C) Luis Gracia <lug2002@med.cornell.edu> 

"
}   


#############################################################################
# Import

proc clustering::import {type} {
  variable clust_file
  variable cluster
  variable level_list

  set clust_file [tk_getOpenFile -title "Cluster filename" -filetypes [list {"Cluster files" {.out .log .dat .clg}} {"All Files" *}] ]

  if {[file readable $clust_file]} {
    set fileid [open $clust_file "r"]
    if {[array exists cluster]} {unset cluster}
    $level_list delete 0 end
    [namespace current]::import_$type $fileid
    close $fileid
  }
}

# NMRCLUSTER (http://neon.chem.le.ac.uk/nmrclust, not working)
proc clustering::import_nmrcluster {fileid} {
  variable level_list
  variable cluster

  # Read data
  set i 0
  while {![eof $fileid]} {
    gets $fileid line
    if { [ regexp {^Members:([ 0-9]+)} $line dummy data ] } {
      incr i 1
      set cluster(0:$i) [[namespace current]::decrease_list $data]
    } elseif { [ regexp {^Outliers:([ 0-9]+)} $line dummy data ] } {
      foreach d $data {
	incr i 1
	set cluster(0:$i) [expr {$d - 1}]
      }
    }
  }
  
  $level_list insert end 0
  $level_list selection set 0
  
  [namespace current]::UpdateLevels
}

# XCLUSTER (http://www.schrodinger.com)
proc clustering::import_xcluster {fileid} {
  variable level_list
  variable cluster

  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    if { [ regexp {^Starting} $line ] } {
    } elseif { [ regexp {^Clustering ([0-9]+); threshold distance ([0-9.]+); ([0-9]+) cluster} $line dummy level threshold ncluster ] } {
      #puts "DEBUG: clustering $level $threshold $ncluster"
      $level_list insert end $level
    } elseif { [ regexp {^Cluster +([0-9]+); Leading member= +([0-9]+); +([0-9]+) members, sep_rat +([0-9.]+)} $line dummy num clust_leader clust_size clust_sep ] } {
      #puts "DEBUG: cluster $num $clust_leader $clust_size $clust_sep"
    } elseif { [ regexp {^([ 0-9]+)$} $line dummy data ] } {
      append cluster($level:$num) [[namespace current]::decrease_list $data]
      #puts "DEBUG: adding level $level cluster $num data $data"
    }
  }
  
  $level_list selection set 0
  
  [namespace current]::UpdateLevels
}

# Output from cutree from R package stats (http://stat.ethz.ch/R-manual/R-patched/library/stats/html/cutree.html)
proc clustering::import_cutree {fileid} {
  variable level_list
  variable cluster

  # Read data
  set sep { }
  
  # - levels
  gets $fileid line
  set levels [split $line $sep]
  #puts "DEBUG: levels [join $levels {, }]"
  foreach level $levels {
    $level_list insert end $level
  }
  
  # - membership
  while {![eof $fileid]} {
    gets $fileid line
    if { [regexp {^$} $line dummy] } {
    } elseif { [regexp {^#} $line dummy] } {
    } else {
      set temp [split $line $sep]
      set obj [lindex $temp 0]
      set membership [lrange $temp 1 end]
      #puts "DEBUG: obj $obj; membership [join $membership {, }]"
      for {set i 0} {$i < [llength $membership]} {incr i} {
	set level [lindex $levels $i]
	set num [lindex $membership $i]
	#puts "DEBUG: assign $i - $level - $num"
	lappend cluster($level:$num) [expr {$obj - 1}]
      }
    }
  }
  $level_list selection set 0
  
  [namespace current]::UpdateLevels
}

# GROMACS, output from g_cluster (http://www.gromacs.org/documentation/reference/online/g_cluster.html)
proc clustering::import_gcluster {fileid} {
  variable level_list
  variable cluster

  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    if { [regexp {^cl\. \|} $line dummy] } {
      #puts "DEBUG: start to read"
    } elseif { [regexp {^\s*(\d+)\s+\|\s+([\d.e-]+)\s+([\d.]+)\s+\|\s+([\d.e-]+)\s+([\d.]+)\s+\|([\s\d.e-]+)} $line dummy num size st_rmsd middle mid_rmsd members ] } {
      # start a new cluster
      #puts "DEBUG: cluster $num size $size middle $middle"
      #puts "DEBUG:    -> $members"
      set cluster(0:$num) $members
      append times $members
    } elseif { [regexp {^\s*(\d+)\s+\|\s+([\d.e-]+)\s+\|\s+([\d.e-]+)\s+\|([\s\d.e-]+)} $line dummy num size middle members ] } {
      # start a new cluster with only one conf
      #puts "DEBUG: cluster $num size $size middle $middle"
      #puts "DEBUG:    -> $members"
      set cluster(0:$num) $members
      append times $members
    } elseif { [regexp {^\s+\|\s+\|\s+\|([\s\d.e-]+)} $line dummy members] } {
      # add conformations to a cluster
      #puts "DEBUG:    -> $members"
      append cluster(0:$num) $members
      append times $members
    } else {
    }
  }

  # Convert time into steps
  set sorted [lsort -real $times]
  for {set i 0} {$i < [llength $sorted]} {incr i} {
    set corr([lindex $sorted $i]) $i
  }
  foreach key [array names cluster] {
    if {[info exists temp2]} {
      unset temp2
    }
    foreach el $cluster($key) {
      lappend temp2 $corr($el)
    }
    set cluster($key) $temp2
  }

  $level_list insert end 0
  $level_list selection set 0

  [namespace current]::UpdateLevels
}

# CHARMM
proc clustering::import_charmm {fileid} {
  variable level_list
  variable cluster

  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    #puts "DEBUG: $line"
    if { [ regexp {^\s+(\d+)\s+(\d+)\s+(\d+)\s+([\d.eE+-]+)} $line dummy num member series distance ] } {
      #puts "DEBUG: $num -> $member -> $series -> $distance"
      lappend cluster(0:$num) [expr {$member - 1}]
    }
  }

  $level_list insert end 0
  $level_list selection set 0

  [namespace current]::UpdateLevels
}


#############################################################################
# Calculate

proc clustering::calculate {} {
  variable cluster
  variable level_list
  variable clust_mol
  variable calc_nclusters
  variable calc_cutoff
  variable calc_first
  variable calc_last
  variable calc_step

  # Get selection
  set seltext [[namespace current]::set_sel]
  if {$seltext == ""} {
    showMessage "Selection is empty selection!"
    return -code return
  }
  set sel [atomselect $clust_mol $seltext]

  # Cluster
  set result [measure cluster $sel num $calc_nclusters cutoff $calc_cutoff first $calc_first last $calc_last step $calc_step]

  set nclusters [llength $result]
  if {$nclusters > 0} {
    if {[array exists cluster]} {unset cluster}
    $level_list delete 0 end

    # Add cluster
    for {set num 0} {$num < [expr {$nclusters - 1}]} {incr num} {
      set cluster(0:$num) [lindex $result $num]
    }

    # Add outliers
    set num [expr {$nclusters - 1}]
    set outliers [lindex $result $num]
    for {set i 0} {$i < [llength $outliers]} {incr i} {
      set cluster(0:$num) [lindex $outliers $i]
      incr num
    }

    $level_list insert end 0
    $level_list selection set 0
    
    [namespace current]::UpdateLevels

  }

}
