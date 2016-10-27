SET SHIP:NAME to "Orbit1".

runoncepath ("lib/utils").

runpath("0:/launch.ks").


set crew_name to SHIP:CREW[0]:NAME.

lock sterring to sun:north.
wait 5.

print ("starting eva").
ADDONS:EVA:GOEVA(SHIP:CREW[0]).

wait 6.
set kerbal_con to vessel(crew_name):connection.
kerbal_con:sendmessage("eva/eva_reports").

print ("Waiting for Kerbal to get back into the ship").
wait until SHIP:CREW:LENGTH > 0.

print ("Kerbal returned to us. heading home").
wait 3.
// return home
set KSC_LNG to (180 - 74.7096270735325).
set MY_LNG to (180 + SHIP:LONGITUDE).
// ToDo fix for planet rotation
set diff_lng to mod((720 + KSC_LNG - MY_LNG),360 ).
local srf_period to ((1/SHIP:ORBIT:PERIOD) - (1/Body:ROTATIONPERIOD))^(-1).
set orbit_time to ((diff_lng-16)/360 *srf_period).

warpfor (orbit_time).

set ignore_autostage to true.
lock steering to retrograde.
wait 5.
lock throttle to 1.0.
wait until ship:AVAILABLETHRUST = 0.
lock steering to up.
wait 5.
stage.
lock steering to retrograde.
wait until SHIP:ALTITUDE < 12000.
unlock steering.
wait until SHIP:ALTITUDE < 6000.
CHUTESSAFE ON.
deploy_chutes().
wait until ( (SHIP:STATUS = "LANDED") OR (SHIP:STATUS = "SPLASHED") ).

if (SHIP:STATUS = "LANDED") {
  wait 2.
  print ("starting eva").
  ADDONS:EVA:GOEVA(SHIP:CREW[0]).
  //time to let the eva load
  wait 6.
  set kerbal_con to vessel(crew_name):connection.
  kerbal_con:sendmessage("eva/take_surface_sample").
}
