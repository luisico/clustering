#
## Clustering Tool
#
## Authors: Luis Gracia
#
## $Id$

## Example code to add this plugin to the VMD extensions menu:
#
#  if { [catch {package require cluster} msg] } {
#    puts "VMD CLUSTER package could not be loaded:\n$msg"
#  } elseif { [catch {menu tk register "cluster" cluster} msg] } {
#    puts "VMD CLUSTER could not be started:\n$msg"
#  }

# Authors:
#   Luis Gracia, PhD, Weill Medical College, Cornel University, NY


# ToDo:
# - use better colors.
# - add link to the help file.
# - control clusters of different molecules:
#   - add a dimension to array cluster.
#   - change in molecule, switches to the cluster.
#   - delete data of a molecule if a molecule no longer exists.




# Tell Tcl that we're a package and any dependencies we may have
package provide cluster 1.0

namespace eval ::CLUSTER:: {
  namespace export cluster
  variable w                         ;# handle to main window

  variable cluster
  variable clust_file
  variable clust_mol
  variable clust_list
  variable clust_level
  variable conf_list
  variable join_1members

}

#############################################################################
# proc ::CLUSTER::getfile {} {
#   variable clust_file
#   variable newfile
  
#   set newfile [tk_getOpenFile \
# 		 -title "Choose filename" \
# 		 -initialdir $clust_file -filetypes {{{Cluster files} {.out .log}}} ]
  
#   if {[string length $newfile] > 0} {
#     set clust_file $newfile
    
#   }
# }

# Add rep for a cluster
proc ::CLUSTER::add_rep { level cluster_num } {
  variable cluster
  variable clust_mol

  foreach f $cluster($level:$cluster_num) {
    lappend frames [expr $f-1]
  }

  set c [expr $cluster_num-1]
  
  mol rep lines
  mol selection [::CLUSTER::set_sel]
  mol addrep $clust_mol
  mol drawframes $clust_mol $c $frames
  mol modcolor $c $clust_mol ColorID $c
  
}

# Delete all reps
proc ::CLUSTER::del_reps { clust_mol } {
  set numreps [molinfo $clust_mol get numreps]
  for {set f 0} {$f <= $numreps} {incr f 1} {
    mol delrep 0 $clust_mol
  }
}

# Set on one or more clusters
proc ::CLUSTER::clus_on { clus } {
  ::CLUSTER::clus_onoff 1 $clus
}

# Set off one or more clusters
proc ::CLUSTER::clus_off { clus } {
  ::CLUSTER::clus_onoff 0 $clus
}

# Set on/off one or more clusters
proc ::CLUSTER::clus_onoff_all { state } {
  variable cluster
  variable clust_level

  set level [$clust_level get [$clust_level curselection]]
  set nclusters [llength [array names cluster $level:*]]
  for {set c 1} {$c <= $nclusters} {incr c 1} {
    ::CLUSTER::clus_onoff $state $c
  }
}

# Set on/off a cluster
proc ::CLUSTER::clus_onoff { state clus } {
  variable clust_mol
  variable cluster
  variable clust_list
  variable conf_list
  variable clust_level
  variable w

  set level [$clust_level get [$clust_level curselection]]
  if { $state == 0 } {
    $clust_list selection clear [expr $clus-1]
  } else {
    $clust_list selection set [expr $clus-1]
  }

  set this $cluster($level:$clus)

  if { $state == 0 } {
    foreach f $this {
      $conf_list selection clear [expr $f-1]
    }
    mol showrep $clust_mol [expr $clus-1] off
  } else {
    foreach f $this {
      $conf_list selection set [expr $f-1]
      lappend frames [expr $f-1]
    }
    mol drawframes $clust_mol [expr $clus-1] $frames
    mol showrep $clust_mol [expr $clus-1] on
  }
}

proc ::CLUSTER::UpdateLevels {} {
  variable clust_level
  variable clust_list
  variable conf_list
  variable clust_mol
  variable cluster

  $clust_list delete 0 end
  $conf_list delete 0 end
  ::CLUSTER::del_reps $clust_mol

  set level [$clust_level get [$clust_level curselection]]
  set nclusters [llength [array names cluster $level:*]]
  #puts "DEBUG: level= $level ; nclusters= $nclusters"

  for {set i 1} {$i <= $nclusters} {incr i} {
    ::CLUSTER::populate $level $i
    ::CLUSTER::add_rep $level $i
  }

  $clust_list selection set 0 [expr $nclusters-1]
  $conf_list selection set 0 end
}

proc ::CLUSTER::populate { level i} {
  variable clust_list
  variable conf_list
  variable clust_mol
  variable cluster
  
  set j [expr $i-1]
  #puts "DEBUG: populate level $level cluster $i"
  $clust_list insert end $i
  $clust_list itemconfigure $j -selectbackground [index2rgb $j]
  foreach this $cluster($level:$i) {
    set size [$conf_list size]
    if {$size < $this} {
      for {set k $size} {$k < $this} {incr k 1} {
	$conf_list insert end [expr $k+1]
      }
    }
    $conf_list itemconfigure [expr $this-1] -selectbackground [index2rgb $j]
  }
}

proc ::CLUSTER::UpdateClusters {} {
  variable clust_list
  variable cluster
  variable clust_level

  set level [$clust_level get [$clust_level curselection]]
  set nclusters [llength [array names cluster $level:*]]

  for {set i 0} {$i < $nclusters} {incr i} {
    set j [expr $i + 1]
    if {[$clust_list selection includes $i]} {
      ::CLUSTER::clus_onoff 1 $j
    } else {
      ::CLUSTER::clus_onoff 0 $j
    }
  }
}

proc ::CLUSTER::UpdateConfs {} {
  variable clust_mol
  variable conf_list
  variable cluster
  variable clust_level
  variable clust_list

  set level [$clust_level get [$clust_level curselection]]
  set nclusters [llength [array names cluster $level:*]]

  
  # Create reverse list
  for {set c 1} {$c <= $nclusters} {incr c 1} {
    foreach f $cluster($level:$c) {
      set confs($f) $c
    }
  }

  # Create list of selected confs
  for {set i 0} {$i < [$conf_list size]} {incr i} {
    if {[$conf_list selection includes $i]} {
      lappend on [expr $i+1]
    }
  }
  
  # create new cluster
  if {![info exists on]} {
    for {set c 0} {$c < $nclusters} {incr c} {
      $clust_list selection clear $c
      mol showrep $clust_mol $c off
    }
    return
  }
  foreach f $on {
    lappend frames($confs($f)) [expr $f-1]
  }

  # apply changes
  set names [array names frames]
  for {set c 0} {$c < $nclusters} {incr c} {
    if {[lsearch -exact $names [expr $c+1]] == -1} {
      $clust_list selection clear $c
      mol showrep $clust_mol $c off
    } else {
      if {[$clust_list selection includes $c] == 0} {
	$clust_list selection set $c
	mol showrep $clust_mol $c on
      }
      mol drawframes $clust_mol $c $frames([expr $c+1])
    }
  }
}

proc ::CLUSTER::UpdateMolecules {} {
  # Code adapted from the ramaplot plugin
  variable w
  variable clust_mol
  
  set mollist [molinfo list]

  # Update the molecule browser
  $w.status.mol_entry.menu delete 0 end
  $w.status.mol_entry configure -state disabled
  if { [llength $mollist] != 0 } {
    foreach id $mollist {
      if {[molinfo $id get filetype] != "graphics"} {
        $w.status.mol_entry configure -state normal 
        $w.status.mol_entry.menu add radiobutton -value $id \
	  -label "$id [molinfo $id get name]" \
	  -variable ::CLUSTER::clust_mol
      }
    }
  }
}

# Convert a VMD color index to rgb
proc ::CLUSTER::index2rgb {i} {
  set len 2
  lassign [colorinfo rgb $i] r g b
  set r [expr int($r*255)]
  set g [expr int($g*255)]
  set b [expr int($b*255)]
  #puts "$i      $r $g $b"
  return [format "#%.${len}X%.${len}X%.${len}X" $r $g $b]
}




#############################################################################
# This gets called by VMD the first time the menu is opened
proc cluster {} {
  ::CLUSTER::cluster
  return $CLUSTER::w
}

#proc cluster_tk_cb {} {
#  variable foobar
#  # Don't destroy the main window, because we want to register the window
#  # with VMD and keep reusing it.  The window gets iconified instead of
#  # destroyed when closed for any reason.
#  #set foobar [catch {destroy $::CLUSTER::w  }]  ;# destroy any old windows
#
#  ::CLUSTER::cluster;
#  return $CLUSTER::w
#}

proc ::CLUSTER::destroy {} {
  # Delete traces
  # Delete remaining selections

  global vmd_initialize_structure
  trace vdelete vmd_initialize_structure w [namespace code UpdateMolecules]

}

#############################################################################
proc ::CLUSTER::cluster {} {
  variable w ;# Tk window

  variable cluster
  variable clust_file
  variable clust_mol
  variable clust_list
  variable clust_level
  variable conf_list
  variable join_1members
  global vmd_initialize_structure

  if {[molinfo num] > 0} {
    set clust_mol [molinfo top get id]
  }

  

  # If already initialized, just turn on
  if { [winfo exists .cluster] } {
    wm deiconify $w
    return
  }

  # Create the window
  set w [toplevel ".cluster"]
  wm title $w "Clustering Tool"
  wm resizable $w 1 1
  bind $w <Destroy> [namespace current]::destroy

  
  # Menubar
  frame $w.top
  frame $w.top.menubar -relief raised -bd 2
  pack $w.top.menubar -padx 1 -fill x -side top

  # Menubar / Import menu
  menubutton $w.top.menubar.import -text "Import" -underline 0 -menu $w.top.menubar.import.menu
  pack $w.top.menubar.import -side left
  menu $w.top.menubar.import.menu -tearoff no
  $w.top.menubar.import.menu add command -label "NMRCLUSTER..."  -command [namespace code import_nmrcluster]
  $w.top.menubar.import.menu add command -label "Xcluster..."  -command [namespace code import_xcluster]

  # Menubar / Help menu
  menubutton $w.top.menubar.help -text "Help" -menu $w.top.menubar.help.menu
  pack $w.top.menubar.help -side right
  menu $w.top.menubar.help.menu -tearoff no
  $w.top.menubar.help.menu add command -label "Help" -command "vmd_open_url page.html"
  
  pack $w.top -fill x

  # Data
  frame $w.data -relief ridge -bd 2

  # Data / Level
  frame $w.data.level
  label $w.data.level.label -text "Levels:"
  pack  $w.data.level.label -side top
  set clust_level [listbox $w.data.level.listbox -selectmode single -activestyle dotbox -width 3 -exportselection 0 -yscroll [namespace code {$w.data.level.scroll set}] ]
  pack  $clust_level -side left -fill y -expand 1
  scrollbar $w.data.level.scroll -command [namespace code {$clust_level yview}]
  pack  $w.data.level.scroll -side left -fill y -expand 1
  bind $clust_level <<ListboxSelect>> [namespace code UpdateLevels]
  pack $w.data.level -side left -fill y -expand 1

  # Data / cluster
  frame $w.data.cluster
  label $w.data.cluster.label -text "Clusters:"
  pack  $w.data.cluster.label -side top
  set clust_list [listbox $w.data.cluster.listbox -selectmode multiple -activestyle dotbox -width 3 -exportselection 0 -yscroll [namespace code {$w.data.cluster.scroll set}] ]
  pack  $clust_list -side left -fill y -expand 1
  scrollbar $w.data.cluster.scroll -command [namespace code {$clust_list yview}]
  pack  $w.data.cluster.scroll -side left -fill y -expand 1
  bind $clust_list <<ListboxSelect>> [namespace code UpdateClusters]
  pack $w.data.cluster -side left -fill y -expand 1

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
  pack $conf_list -side left -fill y -expand 1
  scrollbar $w.data.confs.scroll -command [namespace code {$conf_list yview}]
  pack  $w.data.confs.scroll -side left -fill y -expand 1
  pack $w.data.confs -side left -fill y -expand 1
  bind $conf_list <<ListboxSelect>> [namespace code UpdateConfs]

  pack $w.data -fill y -expand 1

  # Options
  frame $w.options -relief ridge -bd 2

  # Options / join 1 member clusters
  frame $w.options.join
  checkbutton $w.options.join.cb -text "Join 1 member clusters" -variable CLUSTER::join_1members
  pack  $w.options.join.cb -side top -anchor nw
  pack $w.options.join -side top -anchor nw
  $w.options.join.cb configure -state disabled

  # Options / atoms selection
  frame $w.options.sel
  label $w.options.sel.label -text "Selection:"
  pack  $w.options.sel.label -side top -anchor nw
  text $w.options.sel.text -selectborderwidth 0 -exportselection yes -height 3 -width 35 -wrap word
  $w.options.sel.text insert end {noh}
  pack  $w.options.sel.text -side left -fill x -expand 1
  pack $w.options.sel -side left -fill y -expand 1

  pack $w.options -fill y -expand 1

  # Status
  frame $w.status -relief raised -bd 1

  label $w.status.clustfile_label -text "File:"
  pack  $w.status.clustfile_label -side left
  entry $w.status.clustfile_entry -textvariable CLUSTER::clust_file
  pack  $w.status.clustfile_entry -side left -fill x -expand 1

  label $w.status.mol_label -text "Molecule:"
  pack  $w.status.mol_label -side left
  menubutton $w.status.mol_entry -relief raised -bd 2 -direction flush \
	-textvariable ::CLUSTER::clust_mol \
	-menu $w.status.mol_entry.menu
  menu $w.status.mol_entry.menu
  pack  $w.status.mol_entry -side left

  pack $w.status -fill x

  # Set up the molecule list
  trace variable vmd_initialize_structure w [namespace code UpdateMolecules]
  ::CLUSTER::UpdateMolecules
}
  
proc ::CLUSTER::import_nmrcluster {} {
  variable clust_file
  variable clust_level
  variable clust_mol
  variable cluster

  set colors [colorinfo colors]

  set clust_file [tk_getOpenFile \
		    -title "Cluster filename" \
		    -filetypes [list {"Cluster files" {.out .log}} {"All Files" *}] ]
    
  if {[file readable $clust_file]} {
    set fileid [open $clust_file "r"]
    if {[array exists cluster]} {unset cluster}
    $clust_level delete 0 end

    # Read data
    set i 0
    while {![eof $fileid]} {	
      gets $fileid line
      set found 0
      if { [ regexp {^Members:([ 0-9]+)} $line dummy data ] } {
	incr i 1
	set found 1
      } elseif { [ regexp {^Outliers:([ 0-9]+)} $line dummy data ] } {
	incr i 1
	set found 1
      }
      if {$found} {
	set cluster(0:$i) $data
	set found 0
      }

    }
    close $fileid

    $clust_level insert end 0
    $clust_level selection set 0

    ::CLUSTER::UpdateLevels
  }
  return
}

proc ::CLUSTER::import_xcluster {} {
  variable clust_file
  variable clust_level
  variable clust_mol
  variable cluster
  variable join_1members

  puts "$join_1members"
  set colors [colorinfo colors]

  set clust_file [tk_getOpenFile \
		    -title "Cluster filename" \
		    -filetypes [list {"Cluster files" {.clg}} {"All Files" *}] ]
    
  if {[file readable $clust_file]} {
    set fileid [open $clust_file "r"]
    if {[array exists cluster]} {unset cluster}
    $clust_level delete 0 end

    # Read data
    while {![eof $fileid]} {
      gets $fileid line
      if { [ regexp {^Starting} $line ] } {
      } elseif { [ regexp {^Clustering ([0-9]+); threshold distance ([0-9.]+); ([0-9]+) cluster} $line dummy level threshold ncluster ] } {
	#puts "DEBUG: clustering $level $threshold $ncluster"
	$clust_level insert end $level
      } elseif { [ regexp {^Cluster +([0-9]+); Leading member= +([0-9]+); +([0-9]+) members, sep_rat +([0-9.]+)} $line dummy clust_num clust_leader clust_size clust_sep] } {
	if {$clust_num > 1} {
	  if {$join_1members && $clust_size == 1} {
	    lappend outliers $clust_leader
	  } else {
	    set i [expr $clust_num-1]
	    set cluster($level:$i) $data
	    #puts "DEBUG: adding level $level cluster $i data $data"
	  }
	}
	set cont 0
	#puts "DEBUG: cluster $clust_num $clust_leader $clust_size $clust_sep"
      } elseif { [ regexp {^([ 0-9]+)$} $line dummy dataline ] } {
	#puts "dl\t$dataline"
	if {$cont == 0} {
	  set data $dataline
	} else {
	  append data $dataline
	}
	set cont 1
      }
    }
    close $fileid

    # for the last cluster
    if {$join_1members && $clust_size == 1} {
      lappend outliers $clust_leader
    } else {
      set cluster($level:$clust_num) $data
      #puts "DEBUG: adding level $level cluster $i data $data"
    }
    
    # add 1 member clusters all in one cluster (outliers)
    if {$join_1members && [info exists outliers]} {
      set cluster($level:0) $outliers
      puts "DEBUG: adding level $level outliers $outliers"
    }

    $clust_level selection set 0

    ::CLUSTER::UpdateLevels

  }
  return
}

proc ::CLUSTER::set_sel {} {
  variable w
  regsub -all "\#.*?\n" [$w.options.sel.text get 1.0 end] "" temp1
  regsub -all "\n" $temp1 " " temp2
  regsub -all " $" $temp2 "" sel
  return $sel
}
