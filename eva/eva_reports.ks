parameter my_vessel.
runpath ("/lib/science2").

wait 5.

do_science_init().
set starttime to time:seconds.
set allbiomes to LIST().

set WARPMODE TO "PHYSICS".
//set WARP TO 4.

set my_initial_position to (SHIP:POSITION - vessel(my_vessel):position).

// move down the ladder, because we slide up a little :-(
when ((SHIP:POSITION - vessel(my_vessel):position):MAG > (my_initial_position:mag + 0.3 ))  then
{
  addons:eva:move("down").
  wait 1.
  addons:eva:move("stop").
  preserve.
}
when ((SHIP:POSITION - vessel(my_vessel):position):MAG < (my_initial_position:mag - 0.3 ))  then
{
  addons:eva:move("up").
  wait 1.
  addons:eva:move("stop").
  preserve.
}


until ( (time:seconds > (starttime + SHIP:ORBIT:PERIOD)) OR (allbiomes:LENGTH = 3) )  {

  set biome to addons:scansat:CURRENTBIOME.
  if ( not allbiomes:contains(biome) ) {
    print "Found new Biome: " + biome.
    set WARP TO 0.
    wait 0.
    if (addons:scansat:CURRENTBIOME = biome) {
      do_science("eva report").
      allbiomes:add(biome).
      wait 0.
      Addons:EVA:DOEVENT(VESSEL("Orbit1"):rootpart,"Store").
      wait 1.
      do_science_init().
    }
    wait 1.
    set WARPMODE TO "PHYSICS".
    set WARP TO 4.
    }
}

set WARP TO 0.
SET WARPMODE to "RAILS".
addons:eva:board.
