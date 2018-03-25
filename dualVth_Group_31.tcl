proc dualVth {args} {
	parse_proc_arguments -args $args results
	set lvt $results(-lvt)
	set constraint $results(-constraint)
  
  suppress_message NED-045
  suppress_message LNK-041
  suppress_message PWR-601

  set_user_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT
  set_user_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT

	set global_cells_coll [get_cells]
	set global_cells_count [sizeof_collection $global_cells_coll]
	set permitted_numof_lvtcells [expr {round ($global_cells_count * $lvt)}]
  set permitted_numof_hvtcells [expr $global_cells_count - $permitted_numof_lvtcells]
	set global_critical_path_list [get_timing_paths]
  
  proc set_to_lvt {cells_list {count "all"}} {
    set LVT_conv_count 0
    foreach cell $cells_list {
      if { $LVT_conv_count <= $count || $count == "all"} {
        set cell_ref_name [get_attribute -class cell $cell ref_name]
        if {[regexp "_LL" $cell_ref_name] == 0 && [regexp (_LS|_LH) $cell_ref_name] == 1} {
          regsub -all (_LH|_LS) $cell_ref_name "_LL" cell_ref_name
          set res [size_cell $cell CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT/$cell_ref_name]
          set LVT_conv_count [expr $LVT_conv_count + $res]
          puts "$cell_ref_name converted to LVT"
        } else {
           continue
        }
      } else {
        break
      }
    }
    return $LVT_conv_count
  }
  proc set_to_hvt {cells_list {count "all"}} {
    set HVT_conv_count 0
    foreach_in_collection cell $cells_list {
      if { $HVT_conv_count <= $count || $count == "all"} {
        set cell_ref_name [get_attribute -class cell $cell ref_name]
        if {[regexp "_LH" $cell_ref_name] == 0 && [regexp (_LS|_LL) $cell_ref_name] == 1} {     
          regsub -all (_LL|_LS) $cell_ref_name "_LH" cell_ref_name
          set res [size_cell $cell CORE65LPHVT_nom_1.20V_25C.db:CORE65LPHVT/$cell_ref_name]
          set HVT_conv_count [expr $HVT_conv_count + $res]
          puts "$cell converted to HVT"
        } else {
          continue
        }
      } else {
        break
      }
    }
    return $HVT_conv_count
  }
    proc set_to_lvt_alt {cells_list {count "all"}} {
    set LVT_conv_count 0
    foreach_in_collection cell $cells_list {
      if { $LVT_conv_count <= $count || $count == "all"} {
        set cell_ref_name [get_attribute -class cell $cell ref_name]
        if {[regexp "_LL" $cell_ref_name] == 0 && [regexp (_LS|_LH) $cell_ref_name] == 1} {
          regsub -all (_LH|_LS) $cell_ref_name "_LL" cell_ref_name
          set res [size_cell $cell CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT/$cell_ref_name]
          set LVT_conv_count [expr $LVT_conv_count + $res]
          puts "$cell_ref_name converted to LVT"
        } else {
           continue
        }
      } else {
        break
      }
    }
    return $LVT_conv_count
  }
  proc set_to_hvt_alt {cells_list {count "all"}} {
    set HVT_conv_count 0
    foreach cell $cells_list {
      if { $HVT_conv_count <= $count || $count == "all"} {
        set cell_ref_name [get_attribute -class cell $cell ref_name]
        if {[regexp "_LH" $cell_ref_name] == 0 && [regexp (_LS|_LL) $cell_ref_name] == 1} {     
          regsub -all (_LL|_LS) $cell_ref_name "_LH" cell_ref_name
          set res [size_cell $cell CORE65LPHVT_nom_1.20V_25C.db:CORE65LPHVT/$cell_ref_name]
          set HVT_conv_count [expr $HVT_conv_count + $res]
          puts "$cell converted to HVT"
        } else {
          continue
        }
      } else {
        break
      }
    }
    return $HVT_conv_count
  }
  proc find_slack_info {path_coll {debug "dont"}} {
    set design_tns 0
    set design_wns 0
    set design_tps 0
    foreach_in_collection path $path_coll {
      set slack [get_attribute $path slack]
      if {$slack < $design_wns} {
       set design_wns $slack
      }
      if {$slack < 0.0} {
       set design_tns [expr $design_tns + $slack]
      } else {
       set design_tps [expr $design_tps + $slack]
      }
    }
    if {$debug == "spew"} {
      puts "-------------------   SLACK INFO    -----------------------"
      puts [format "Worst Negative Slack : %g" $design_wns]
      puts [format "Total Negative Slack : %g" $design_tns]
      puts [format "Total Positive Slack : %g" $design_tps]
    }
    return $design_wns
  }
  proc find_critical_path_cells {{debug "dont"}} {
    set tcp_cells_list [list]
    set ctp_points [get_attribute [get_timing_paths -path_type full -delay_type max -max_paths 1] points]
    foreach_in_collection ctp_point $ctp_points {
      set ctp_pin_name [get_attribute [get_attribute $ctp_point object] full_name]
      if {[string index $ctp_pin_name "0"] == "U"} {
        set ctp_cell [lindex [split $ctp_pin_name '/'] 0]
        if {$ctp_cell != [lindex $tcp_cells_list end]} {
          lappend tcp_cells_list $ctp_cell
        }   
      }
    }
    if {$debug == "spew"} {
      puts "---------------   CRITICAL PATH INFO   --------------------"
      puts [format "Cells list : $tcp_cells_list"]
    }
    return $tcp_cells_list
  }
  proc find_cells_from_path { path {debug "dont"} } {
    set tbp_cells_list [list]
    set btp_points [get_attribute $path points]
    foreach_in_collection btp_point $btp_points {
      set btp_pin_name [get_attribute [get_attribute $btp_point object] full_name]
      if {[string index $btp_pin_name "0"] == "U"} {
        set btp_cell [lindex [split $btp_pin_name '/'] 0]
        if {$btp_cell != [lindex $tbp_cells_list end]} {
          lappend tbp_cells_list $btp_cell
        }   
      }
    }
    if {$debug == "spew"} {
      puts "---------------   CRITICAL PATH INFO   --------------------"
      puts [format "Cells list : $tbp_cells_list"]
    }
    return $tbp_cells_list
  }
  proc find_power {{debug dont}} {
    set leakage_power [get_attribute [get_design] leakage_power]
    if {$debug == "spew"} {
      set total_power [get_attribute [get_design] total_power]
      puts "-------------------   POWER INFO    -----------------------"
      puts [format "Total power : %g" $total_power]
      puts [format "Leakage power : %g" $leakage_power]
    }
    return $leakage_power
  }

	if { $lvt > 1.0 || $lvt < 0.0 } {
		puts "Illegal value for argument 1; should be in range{0.0-1.0} \nExiting..."
		return
	} else {
		puts "Starting dual Vth assignment process..."
		puts "According to the user constraint, max $permitted_numof_lvtcells of $global_cells_count can be converted to LVT."
    puts "-----------------    INITIAL STATS    ---------------------"
    set initial_slack [find_slack_info [get_timing_paths] spew]
    set initial_leakage_power [find_power spew]
    if {$constraint == "hard"} {
      set hvtcellsnum [set_to_hvt [get_cells]]
      puts "$hvtcellsnum cells converted to HVT"
      set redundant_iteration 0
      while {[find_power] < [expr 0.9 * $initial_leakage_power] && $permitted_numof_lvtcells > 0 && $redundant_iteration < 25} {
        set converted_lvtcells [set_to_lvt [find_critical_path_cells] 1]
        set permitted_numof_lvtcells [expr $permitted_numof_lvtcells - $converted_lvtcells]
        if {$converted_lvtcells == 0} {set $redundant_iteration [expr {$redundant_iteration + 1}]}
      }
    puts "-----------------    AFTER DUALVTH ASSIGNMENT    ---------------------"
    find_slack_info [get_timing_paths] spew
    find_power spew
		return
    } elseif {$constraint == "soft"} {
      set lvtcellsnum [set_to_lvt_alt [get_cells]]
      puts "$lvtcellsnum cells converted to LVT"
      set redundant_iteration 0
      while {$redundant_iteration < 25} {
        set converted_hvtcells 0
        set path_list [get_timing_paths -path_type full -max_paths 5000 -delay_type min -slack_greater_than 0]
        foreach_in_collection path_list_obj $path_list {
          set slack_list_obj [find_slack_info $path_list_obj]
          set kvp($path_list_obj) $slack_list_obj
        }
        foreach path [array names kvp] {
          if {[find_slack_info $path] >= 0} {
            set count 0
            if {$permitted_numof_hvtcells > 0} {
              set count [set_to_hvt_alt [find_cells_from_path $path]]
            }
            if {[find_slack_info [get_timing_paths]] < 0} {
              set_to_lvt [find_cells_from_path $path]
            } else {
              set converted_hvtcells [expr $converted_hvtcells + $count]
              set permitted_numof_hvtcells [expr $permitted_numof_hvtcells - $count]
            }
          }
        }
        if {$converted_hvtcells <= 0} {
          set redundant_iteration [expr $redundant_iteration + 1]
        }
        unset kvp
        unset path_list
      }
      puts "-----------------    AFTER DUALVTH ASSIGNMENT    ---------------------"
      find_slack_info [get_timing_paths] spew
      find_power spew
      return
    }
  }
}
define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth cell assignment" \
-define_args \
{
	{-lvt "maximum % of LVT cells in range [0, 1]" lvt float required}
	{-constraint "optimization effort: soft or hard" constraint one_of_string {required {values {soft hard}}}}
}