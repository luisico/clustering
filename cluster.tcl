##
## Clustering Tool 1.0
##
## Authors: Luis Gracia
##
## $Id$
##

##
## Example code to add this plugin to the VMD extensions menu:
##
#  if { [catch {package require cluster} msg] } {
#    puts "VMD CLUSTER package could not be loaded:\n$msg"
#  } elseif { [catch {menu tk register "cluster" cluster} msg] } {
#    puts "VMD CLUSTER could not be started:\n$msg"
#  }

# Authors:
#   Luis Gracia, PhD, Weill Medical College, Cornel University, NY

# Tell Tcl that we're a package and any dependencies we may have
package provide cluster 1.0

namespace eval ::CLUSTER:: {
  namespace export cluster
  variable w                         ;# handle to main window

  variable cluster
  variable clust_file
  variable clust_mol
  variable clust_list

  # Calmer color scheme that looks like other plugins
  variable ftr_bgcol   \#d9d9d9
  variable ftr_fgcol   \#000
  variable calc_bgcol  \#d9d9d9
  variable calc_fgcol  \#000
  variable sel_bgcol   \#ff0
  variable sel_fgcol   \#000
  variable act_bgcol   \#d9d9d9
  variable act_fgcol   \#000
  variable entry_bgcol \#fff
  variable but_abgcol  \#d9d9d9
  variable but_bgcol   \#d9d9d9
  variable scr_trough  \#c3c3c3
}

#############################################################################
# This gets called by VMD the first time the menu is opened
proc cluster_tk_cb {} {
  variable foobar
  # Don't destroy the main window, because we want to register the window
  # with VMD and keep reusing it.  The window gets iconified instead of
  # destroyed when closed for any reason.
  set foobar [catch {destroy $::CLUSTER::w  }]  ;# destroy any old windows

  ::CLUSTER::cluster;
  return $CLUSTER::w
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

# Reps for each frame
proc ::CLUSTER::set_reps {} {
  variable clust_mol
  set nframes [molinfo $clust_mol get numframes]
  for {set f 0} {$f < $nframes} {incr f 1} {
    mol rep lines
    mol selection {name CA C N}
    mol addrep $clust_mol
    mol drawframes $clust_mol $f $f
  }
}

# Modify color
proc ::CLUSTER::col_reps {} {
  variable cluster
  variable clust_mol
  set nclusters [array size cluster]
  puts "b $nclusters"
  for {set c 1} {$c <= $nclusters} {incr c 1} {
    puts $cluster($c)
    set this $cluster($c)
    foreach f $this {
      mol modcolor [expr $f-1] $clust_mol ColorID $c
    }
  }
}

# Delete all reps
proc ::CLUSTER::del_reps {} {
  variable clust_mol
  set nframes [molinfo $clust_mol get numframes]
  for {set f 0} {$f <= $nframes} {incr f 1} {
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
  set nclusters [array size cluster]
  for {set c 1} {$c <= $nclusters} {incr c 1} {
    ::CLUSTER::clus_onoff $state $c
  }
}

# Set on/off a cluster
proc ::CLUSTER::clus_onoff { state clus } {
  variable clust_mol
  variable cluster
  variable clust_list
  set this $cluster($clus)
  foreach f $this {
    if { $state == 0 } {
      mol showrep $clust_mol [expr $f-1] off
      $clust_list selection clear [expr $clus -1]
    } else {
      mol showrep $clust_mol [expr $f-1] on
      $clust_list selection set [expr $clus -1]
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
proc ::CLUSTER::cluster {} {
  variable w ;# Tk window

  variable cluster
#  variable w
  variable clust_file
  variable clust_mol
  variable clust_list

  variable ftr_bgcol 
  variable ftr_fgcol 
  variable calc_bgcol
  variable calc_fgcol
  variable sel_bgcol
  variable sel_fgcol
  variable act_bgcol   
  variable act_fgcol   
  variable entry_bgcol 
  variable but_abgcol  
  variable but_bgcol   
  variable scr_trough 

  set clust_mol [molinfo top get id]

  # If already initialized, just turn on
  if { [winfo exists .cluster] } {
    wm deiconify $w
    return
  }

  # Create the window
  set w [toplevel ".cluster" -bg $calc_bgcol]
  wm title $w "CLUSTER"
  wm resizable $w 1 1

  
  # Create menubar
  frame $w.top
  frame $w.top.menubar -relief raised -bd 2
  pack $w.top.menubar -padx 1 -fill x -side top

  # Import menu
  menubutton $w.top.menubar.import -text "Import" -underline 0 -menu $w.top.menubar.import.menu
  pack $w.top.menubar.import -side left
  menu $w.top.menubar.import.menu -tearoff no
  $w.top.menubar.import.menu add command -label "NMRCLUSTER..."  -command [namespace code import_nmrcluster]

#   # Help menu
  menubutton $w.top.menubar.help -text "Help" -menu $w.top.menubar.help.menu
  pack $w.top.menubar.help -side right
  menu $w.top.menubar.help.menu -tearoff no
  $w.top.menubar.help.menu add command -label "Help" -command "vmd_open_url [string trimright [vmdinfo www] /]/plugins/ramaplot"
  
  pack $w.top -fill x

  # Data
  frame $w.data

  frame $w.data.cluster
  label $w.data.cluster.label -text "Clusters:"
  pack  $w.data.cluster.label -side top

  set clust_list [listbox $w.data.cluster.listbox -selectmode multiple -activestyle dotbox -width 3 -exportselection 1 -yscroll [namespace code {$w.data.cluster.scroll set}] ]
  pack  $clust_list -side left -fill y -expand 1

  scrollbar $w.data.cluster.scroll -command [namespace code {$clust_list yview}]
  pack  $w.data.cluster.scroll -side left -fill y -expand 1

  bind $clust_list <<ListboxSelect>> [namespace code {
    for {set i 0} {$i < [array size cluster]} {incr i} {
      set j [expr $i + 1]
      if {[$clust_list selection includes $i]} {
	::CLUSTER::clus_on $j
      } else {
	::CLUSTER::clus_off $j
      }
    }
  }]

  pack $w.data.cluster -side left -fill y -expand 1

  frame $w.data.buttons
  button $w.data.buttons.all -text "All" -command [namespace code {clus_onoff_all 1}]
  pack $w.data.buttons.all -side top
  button $w.data.buttons.none -text "None" -command [namespace code {clus_onoff_all 0}]
  pack $w.data.buttons.none -side top

  pack $w.data.buttons -side left

  pack $w.data -fill y

  # Status
  frame $w.status -relief raised -bd 1

  label $w.status.clustfile_label -text "File:"
  pack  $w.status.clustfile_label -side left
  entry $w.status.clustfile_entry -textvariable CLUSTER::clust_file
  pack  $w.status.clustfile_entry -side left -fill x -expand 1

  label $w.status.mol_label -text "Molecule:"
  pack  $w.status.mol_label -side left
  entry $w.status.mol_entry -width 3 -textvariable CLUSTER::clust_mol
  pack  $w.status.mol_entry -side left

  pack $w.status -fill x

}
  

proc ::CLUSTER::import_nmrcluster {} {
  variable clust_file
  variable clust_list
  variable cluster

  set colors [colorinfo colors]

  set clust_file [tk_getOpenFile \
		    -title "Cluster filename" \
		    -filetypes [list {"Cluster files" {.out .log}} {"All Files" *}] ]
    
  if {[file readable $clust_file]} {
    set fileid [open $clust_file "r"]
    if {[array exists cluster]} {unset cluster}
    $clust_list delete 0 end
    set i 0
    while {![eof $fileid]} {	
      gets $fileid line
      if { [ regexp {^Members:([ 0-9]+)} $line dummy data ] } {
	incr i 1
	set cluster($i) $data
	$clust_list insert end $i
	$clust_list itemconfigure [expr $i-1] -selectbackground [index2rgb $i]

      } elseif { [ regexp {^Outliers:([ 0-9]+)} $line dummy data ] } {
	incr i 1
	set cluster($i) $data
	$clust_list insert end $i
      }
    }
    close $fileid

    $clust_list selection set 0 [expr $i -1]

    ::CLUSTER::del_reps
    ::CLUSTER::set_reps
    ::CLUSTER::col_reps



  }
  return
}


