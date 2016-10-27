parameter my_vessel.
runpath ("/lib/science2").

wait 5.


do_science_init().

//set WARP TO 4.


addons:eva:move("down").
wait until ALT:RADAR < 0.3.
addons:eva:move("stop").

addons:eva:LADDER_RELEASE.

print "turning".
set ship_dist to VESSEL(my_vessel):position:mag.
addons:eva:turn_right(180).

wait 2.
addons:eva:move("forward").
wait until (VESSEL(my_vessel):position:mag > (ship_dist+5)).
addons:eva:move("stop").

//do_science("take surface sample").
//wait 1.
do_science("eva report").
wait 1.

addons:eva:PLANTFLAG(my_vessel + " landing site","kOS Rules!!").
wait 4.
addons:eva:turn_to(VESSEL(my_vessel):position).
wait 2.
addons:eva:move("forward").
wait until (VESSEL(my_vessel):position:mag < (ship_dist+0.05)).
addons:eva:move("stop").

addons:eva:LOADANIMATION("\kOS-EVA\Anims\Wave.anim").
addons:eva:turn_left(180).
wait 2.
addons:eva:PlayAnimation("Wave").
wait 2.
addons:eva:StopAnimation("Wave").
addons:eva:turn_right(180).
wait 2.

addons:eva:LADDER_GRAB.
addons:eva:move("up").
wait until (alt:radar > 1).
addons:eva:move("stop").

addons:eva:board.
