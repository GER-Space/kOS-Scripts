@LAZYGLOBAL OFF.
// lock STEERING to steering_dir(PROGRADE).

function eta_apsis {
	if ETA:APOAPSIS > 0 {
		return  min(ETA:APOAPSIS, ETA:PERIAPSIS).
	} else {
		return ETA:PERIAPSIS.
	}
}

function steering_dir {
  declare local parameter dir.
  return LOOKDIRUP(dir:VECTOR, FACING:TOPVECTOR).
}



function set_inc_lan{
	declare local parameter incl_t.
	declare local parameter lan_t.
	if SHIP:ORBIT:ECCENTRICITY < 0.05 {
		set_inc_lan_i(incl_t,lan_t).
	} else {
		set_inc_lan_ecc(incl_t,lan_t).
	}
}


function set_inc_lan_i {
	declare local parameter incl_t.
	declare local parameter lan_t.
	declare local parameter fast is true.
	print " ".
	local incl_i to SHIP:OBT:INCLINATION.
	local lan_i to SHIP:OBT:LAN.

	// setup the vectors; Transform spherical to cubic coordinates.
	local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
	local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
	// important to use the reverse order
	local Vc to VCRS(Vb,Va).

	local d_inc to arccos (vdot(Va,Vb) ).
	local dvtgt to (2 * (SHIP:OBT:VELOCITY:ORBIT:MAG) * SIN(d_inc/2)).

	//compute burn_point and set to the range of [0,360]
	local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).

	local ship_rad to mod(OBT:LAN+OBT:argumentofperiapsis+OBT:trueanomaly,360).
	local node_eta to SHIP:OBT:PERIOD * ((mod(node_lng - ship_rad + 360,360))) / 360.


	// Switch to DN, dV is probably right
	if node_eta > ((SHIP:OBT:PERIOD) / 2) AND fast {
		print "Switching to DN".
		set node_eta to ((SHIP:OBT:PERIOD / 2) + (node_eta-SHIP:OBT:PERIOD)).
		set dvtgt to 0-dvtgt.
	}

	print "inc_Burn dV: " + round(dvtgt,2).
	print "inc_Burn ETA: " + round(node_eta,2).

	// Create a blank node
	local inc_node to NODE(time:seconds+node_eta, 0, 0, 0).
	//	we need to split our dV to normal and prograde
	set inc_node:NORMAL to dvtgt * cos(d_inc/2).
	// always burn retrograde
	set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
	ADD inc_node.
}

// Wrapper
function mk_change_inc_node {
	declare local parameter target_inc.
		set_inc_lan (target_inc,SHIP:OBT:LAN).
}

// matches inclination and LAN with target
function match_plane {
	declare local parameter my_target.
	local do_end to false.
	local common_body to "".
	local my_new_target to "".
	local tgt_index to 0.
	if my_target:BODY:NAME = SHIP:BODY:NAME {
		set_inc_lan (my_target:OBT:INCLINATION,my_target:OBT:LAN).
	} else {
		if my_target:BODY = Sun AND (SHIP:BODY = Kerbin OR SHIP:BODY = Mun) {
			set_inc_lan (my_target:OBT:INCLINATION,my_target:OBT:LAN).
		}
	}
}

// Legacy
//Code by baloan (kos wiki mtkv4)
function warpfor {
	declare local parameter dt.
	local t1 to time:seconds + dt.
	if dt < 0 {
		print "T+" + round(missiontime) + " Warning: wait time " + round(dt) + " is in the past.".
	}
	local oldwp to 0.
	local oldwarp to warp.
	until time:seconds >= t1 {
		local rt to t1 - time:seconds.       // remaining time
		local wp to 0.
		if rt > 5      { set wp to 1. }
		if rt > 10     { set wp to 2. }
		if rt > 50     { set wp to 3. }
		if rt > 100    { set wp to 4. }
		if rt > 1000   { set wp to 5. }
		if rt > 10000  { set wp to 6. }
		if rt > 100000 { set wp to 7. }
		if wp <> oldwp OR warp <> wp {
			set warp to wp.
			wait 0.04.
			set oldwp to wp.
			set oldwarp to warp.
		}
    wait 0.04.
	}
	wait until ((SHIP:LOADED) AND (SHIP:UNPACKED)) .
}

//New Version.
function warpfor__ {
	declare local parameter warptime.
	if warptime < 0 {
		print " Warning: wait time " + round(warptime) + " is in the past.".
		return.
	}
	warpto(time:seconds + warptime).

}


// Node runner function. executes the next node. (from kos-doc toturial)
function run_node{
	SAS off.
	local nd to NEXTNODE.
	//print out node's basic parameters - ETA and deltaV
	if nd:deltav:mag < 0.15 {
		print "not enough dV in Node --> removing NODE!" .
		remove nd.
		return.
	}
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

	local burn_duration to get_burn_t(nd:deltav:mag).
	print "Estimated burn duration: " + round(burn_duration) + "s".

	// at the time of node:eta and we accelerrate more in the last halve.
	local burn_duration_first_halve to get_burn_t(nd:deltav:mag/2).

	// we want to lock the vector, so we get better accuracy
	local lock np to lookdirup(nd:deltav, ship:facing:topvector). //points to node, keeping roll the same.
	lock steering to np.
	print "waiting for the ship to turn".
	local t_start to  time:seconds.
	//now we need to wait until the burn vector and ship's facing are aligned
	wait until (VANG(np:VECTOR,SHIP:FACING:VECTOR) < 0.1)  OR (time:seconds > t_start+60).
	print "waiting done".

	//the ship is facing the right direction, let's wait for our burn time
	warpfor (nd:eta - (burn_duration_first_halve + 12)).
	wait until nd:eta <= (burn_duration_first_halve).

	local tset to 0.
	lock throttle to tset.

	local done to False.
	//initial deltav
	local dv0 to nd:deltav.
	local max_acc is 0.

	print "using time based burn.".
	lock max_acc to ship:maxthrust/ship:mass.
	lock tset to min(nd:deltav:mag/max_acc, 1).
	// the burn vector is behind me.
	when (vdot(nd:deltav,SHIP:FACING:VECTOR:normalized) < 0.005) THEN {
		set tset to 0.
		set done to true.
	}.
	until done {
		wait 0.001.
		if (nd:deltav:MAG < 1) {
			local my_dir to lookdirup(nd:deltav, ship:facing:topvector).
			lock steering to my_dir.
			wait until nd:deltav:MAG < 0.3.
			set my_dir to lookdirup(nd:deltav, ship:facing:topvector).
		}
	}
	//we no longer need the maneuver node
	remove nd.
	print "Runnode Finished".

	// this is for the solar panels
	lock steering to lookdirup(SUN:NORTH:VECTOR,SUN:POSITION).
	wait 7.

	//set throttle to 0 just in case.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
}


// usage: set_altitude(when,alt_in_meter).
function set_altitude {
	declare local parameter node_eta,target_alt.
	print "setting Altitude of " + round(target_alt/1000,2) + " km".
	local v_burn to VELOCITYAT(SHIP,time:seconds + node_eta).
	local r_burn to (POSITIONAT(SHIP,time:seconds + node_eta) - BODY:POSITION):MAG.
	local semi_major_axis_new to (r_burn + target_alt + BODY:RADIUS)/2.
	// Vis-viva with new sma
	local v_target to sqrt(BODY:MU * (2/r_burn - 1/semi_major_axis_new)).
	local node_dv to v_target - v_burn:ORBIT:MAG.
	local my_node to NODE(time:seconds + node_eta,0,0,node_dv).
	add my_node.
}



// Takes the dV and returns the expected burn time without staging.
function get_burn_t {
	declare local parameter dV.

	local e is CONSTANT:E.
	local eng_stats is get_engine_stats().
	local mass_rate is eng_stats[2].
	local v_e is eng_stats[3].

	// Rocket equation solved for t.
	local burn_t is  SHIP:MASS*(1 - e^(-dV/v_e))/mass_rate.

	return burn_t.
}


// returns commulative thrust, mean isp, the mass change and the mean_exit_velocity of all engines of this stage.
function get_engine_stats {


	local g is 9.80665.	// Engines use this.

	local all_thrust is 0.
	local old_isp_devider is 0.
	local all_engines is LIST().

  	list ENGINES in all_engines.
	for eng in all_engines {
		if eng:IGNITION AND NOT eng:FLAMEOUT {
			set all_thrust to (all_thrust + eng:AVAILABLETHRUST).
			set old_isp_devider to (old_isp_devider + (eng:AVAILABLETHRUST / eng:VISP)).
		}
	}

	local mean_isp is (all_thrust / old_isp_devider).
	local ch_rate is all_thrust/(g*mean_isp).
	local exit_velocity is all_thrust/ch_rate.

	return list(all_thrust , mean_isp , ch_rate , exit_velocity).
}


// Code by Ozin
function circularize {
	local th to 0.
	lock throttle to th.
	local dV is ship:facing:vector:normalized. //temporary
	lock steering to lookdirup(dV, ship:facing:topvector).
	ag1 off. //ag1 to abort

	local timeout is time:seconds + 9000.
	when dV:mag < 0.5 then set timeout to time:seconds + 3.

	until ag1 or dV:mag < 0.02 or time:seconds > timeout {
		local vecNormal to vcrs(up:vector,velocity:orbit).
		local vecHorizontal to -1 * vcrs(up:vector, vecNormal).
		set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
		set dV to vecHorizontal - velocity:orbit. //deltaV as a vector

		//throttle control
		if vang(ship:facing:vector,dV) > 1 {
			set th to 0. //Throttle to 0 if not pointing the right way
		} else {
			set th to max(0,min(1,dV:mag/10)).  //lower throttle gradually as remaining deltaV gets lower
		}
		wait 0.
	}
	set th to 0.
}

// set the burn for apoapsis at the desired spot.
// called from a circular orbit.
// apoapsis is the opposite of periapsis.
function set_argp {
	local parameter arg_p,new_apoapsis.
	print "setting up node with arg_p: " + arg_p + " and apoapsis: " + new_apoapsis + "km".
	local argp_ref to mod(SHIP:ORBIT:LAN + arg_p,360).
	local ship_ref to SHIP:ORBIT:LAN + SHIP:ORBIT:ARGUMENTOFPERIAPSIS + SHIP:ORBIT:TRUEANOMALY.
	local angle_2_node to mod(720 + argp_ref - ship_ref,360).
	local time_2_node to angle_2_node*SHIP:ORBIT:PERIOD/360.
	set_altitude(time_2_node,new_apoapsis).
}


//
//  converts the current SHIP and target True-anomaly to mean_anomaly and then takes the time difference.
//
function eta_true_anom {
	declare local parameter tgt_true_anom.
	// convert the positon from reference to deg from PE (which is the true anomaly)
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	// s_ref = lan + arg + referenc

	print "Target anomaly   : " + round(tgt_true_anom,2).
	local tgt_eta to 0.
	local ecc to OBT:ECCENTRICITY.
	if ecc < 0.001 {
		set tgt_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

	} else {
		local tgt_eccentric_anomaly to	arccos((ecc + cos(tgt_true_anom)) / (1 + ecc * cos(tgt_true_anom))).
		local tgt_mean_anom to (tgt_eccentric_anomaly - (Constant:RadToDeg * (ecc * sin(tgt_eccentric_anomaly)))).

		// time from periapsis to point
		local time_2_anom to  SHIP:OBT:PERIOD * tgt_mean_anom /360.

		local my_eccentric_anomaly to	arccos((ecc + cos(SHIP:OBT:TRUEANOMALY)) / (1 + ecc * cos(SHIP:OBT:TRUEANOMALY))).
		local my_mean_anom to (my_eccentric_anomaly - (Constant:RadToDeg * (ecc * sin(my_eccentric_anomaly)))).

		local my_time_in_orbit to (my_mean_anom*OBT:PERIOD /360).
		set tgt_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

	}

	return tgt_eta.
}

function set_inc_lan_ecc {
	declare local parameter incl_t.
	declare local parameter lan_t.
	local incl_i to SHIP:OBT:INCLINATION.
	local lan_i to SHIP:OBT:LAN.

// setup the vectors to highest latitude; Transform spherical to cubic coordinates.
	local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
	local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
// important to use the reverse order
	local Vc to VCRS(Vb,Va).

	local dv_factor to 1.
	//compute burn_point and set to the range of [0,360]
	local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

	local ship_2_node to mod((720 + node_lng - ship_ref),360).
	if ship_2_node > 180 {
		print "Switching to DN".
		set dv_factor to -1.
		set node_lng to mod(node_lng + 180,360).
	}


//	local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
	local tgt_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).
	local ecc to OBT:ECCENTRICITY.
//	local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(tgt_true_anom)) ).
//	local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).
	local node_eta to eta_true_anom(tgt_true_anom).
	local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
	local d_inc to arccos (vdot(Vb,Va) ).
	local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).

	// Create a blank node
	local inc_node to NODE(node_eta, 0, 0, 0).
//	we need to split our dV to normal and prograde
	set inc_node:NORMAL to dvtgt * cos(d_inc/2).
	// always burn retrograde
	set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
	set inc_node:ETA to node_eta.

	ADD inc_node.
}
