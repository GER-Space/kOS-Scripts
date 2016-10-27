@LAZYGLOBAL OFF.
local parameter  incl is 0.
clearscreen.


//includes
runoncepath ("0:/lib/auto").
runoncepath ("0:/lib/nav2").
//includes

local target_alt to (SHIP:BODY:ATM:HEIGHT + 30000).

// inclination setup
local incl_init to 0.
if incl = 0 {
	set incl_init to 90.
} else {
	set incl_init to arcsin( cos(incl) /cos(SHIP:LATITUDE) ).
}
print "Launching for inclination: " + incl .
local PI to constant:pi.
local v_eqrot to 2* PI * SHIP:BODY:RADIUS / SHIP:BODY:ROTATIONPERIOD.
local v_orbit to sqrt ( SHIP:BODY:MU / (SHIP:BODY:RADIUS  + target_alt)).

local my_dir to arctan ((v_orbit * sin(incl_init) - v_eqrot*cos(SHIP:LATITUDE) ) /( v_orbit *cos(incl_init) ) ).
print "Setting Direction to: " + round(my_dir,1).



// Launch Vector setup
function v_rotate{
	local parameter vec_from,vec_to,deg.
	return ((cos(deg) * vec_from) + (sin(deg) * vec_to)).
}

local my_pitch to 90.
local vec_surface to heading(my_dir,0):vector.

local vec_burn to v_rotate( vec_surface ,UP:VECTOR ,my_pitch).
lock steering to lookdirup(vec_burn, SHIP:FACING:TOPVECTOR).

local my_heading to vang(BODY:NORTH:VECTOR,vec_surface).


local vec_down to vdot (UP:VECTOR,SHIP:VELOCITY:SURFACE)*UP:VECTOR.

// Ascending and Turning Code
local need_turn to TRUE.
local once to TRUE.
local do_turn to TRUE.
local initial_pitch to 10.

local turn_end to (SHIP:BODY:ATM:HEIGHT).
if turn_end = 0 {
	set turn_end to 7000.
}

// Startup and launch.

print "starting up".

SAS off.

lock THROTTLE to 0.0 .

print "". print "Countdown". print "".
print "3". wait 1.
print "2". wait 1.
print "1".
wait 0.9. print "Engines Start".
lock THROTTLE to 1.0 .
wait 0.1.
//stage.
init_launch_autofunctions().
autostage().

//Debug vectors
// local draw_surface to VECDRAWARGS(ship:position, vec_surface, RGB(1,1,1), "initial surface", 5, true).
// local draw_burn to VECDRAWARGS(ship:position, vec_burn  , RGB(1,0,1), "burn vector", 20, true).

UNTIL SHIP:OBT:APOAPSIS > target_alt {

//Debug vectors
//    set draw_surface to VECDRAWARGS(ship:position, vec_surface, RGB(1,1,1), "initial surface", 5, true).
//	set draw_burn to VECDRAWARGS(ship:position, vec_burn , RGB(1,0,1), "burn vector", 20, true).

	// slightly pitch over.
	if need_turn AND ALT:RADAR > 100 {
		if once {
			print "Initial pitch started".
			set once to FALSE.
		}
		if SHIP:OBT:APOAPSIS > turn_end {
			set turn_end to turn_end + 5000.
		}

		local pitch_rate to ((initial_pitch)/900).
		set my_pitch to((arccos (sqrt(SHIP:OBT:APOAPSIS/turn_end))) -((ALT:RADAR-100) *pitch_rate)).
		if ALT:RADAR > 990 {
			print "Initial pitch completed".
			set need_turn to FALSE.
			set once to true.
		}

	}
	if  ALT:RADAR > 1000{
		if do_turn {
			set my_pitch to (arccos (sqrt(SHIP:OBT:APOAPSIS/turn_end))-initial_pitch).
		}
	}
	// we finished pitching down.
	if my_pitch < 0 {
		print "Turn completed".
		set do_turn to FALSE.
		set need_turn to FALSE.
		set my_pitch to 0.

	}
	// ignore the initial vector and use our different velocities
	if  SHIP:VELOCITY:ORBIT:MAG > v_orbit/3 {
		if once {
			print "Switching to vector based burning".
			set once to FALSE.
	}
	// we reached our target inclination.
		if incl - SHIP:ORBIT:INCLINATION < 0.01 {
			set vec_down to vdot (UP:VECTOR,SHIP:VELOCITY:ORBIT)*UP:VECTOR.
			set vec_surface to ((SHIP:VELOCITY:ORBIT - vec_down)):NORMALIZED.
		// we want to burn in the direction of the surface direction to increase our inclination.
		} else {
			set vec_down to vdot (UP:VECTOR,SHIP:VELOCITY:SURFACE)*UP:VECTOR.
			set vec_surface to ((SHIP:VELOCITY:SURFACE - vec_down)):NORMALIZED.
		}
	}

	set my_heading to vang(BODY:NORTH:VECTOR,vec_surface).
	set vec_burn to v_rotate(vec_surface ,UP:VECTOR ,my_pitch).

	auto_asparagus().
	autostage().
    print "alt:radar: " + round(ALT:RADAR) + "  " at (0,33).
    print "Thrust:    " + round(SHIP:AVAILABLETHRUST,1) + "   " at (0,34).
	print "pitch:   " + round(my_pitch,1) + "  " at (20,33).
	print "heading: " + round(my_heading,2) + "  " at (20,34).

	wait 0.1.
}

// Ascending Finished. Circlet Code and other Stuff

lock THROTTLE to 0 .

print "waiting for exit of atmosphere".
set WARPMODE TO "PHYSICS".
set WARP TO 2.
wait until SHIP:ALTITUDE > BODY:ATM:HEIGHT.

set WARP TO 0.
set WARPMODE TO "RAILS".

PANELS on.

init_autostage().
set_altitude(ETA:APOAPSIS,(SHIP:ORBIT:APOAPSIS)).

wait 2.

run_node().
circularize().

//giving back control.
SAS off .
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
