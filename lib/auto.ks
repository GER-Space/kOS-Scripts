
function autostage {

	if not (defined ignore_autostage) {global ignore_autostage to false.}.
	if NOT ignore_autostage AND SHIP:AVAILABLETHRUST = 0 AND ( (SHIP:LIQUIDFUEL > 0) OR (SHIP:SOLIDFUEL > 0 )) {

		local num_reserve to 0.
		local my_engines to LIST().
		list ENGINES in my_engines.
		FOR eng in my_engines {
			if NOT eng:FLAMEOUT
			{
				set num_reserve to num_reserve +1.
			}
		}
			print (num_reserve -1) + " Engines left for Staging".
			stage.
			init_autoasparagus().
			wait 1.0.

	}
}

// the function from above, just as a WHEN trigger
function init_autostage {

	if defined ignore_autostage { } else {global ignore_autostage to false.}.
	WHEN NOT ignore_autostage AND SHIP:AVAILABLETHRUST = 0 AND SHIP:LIQUIDFUEL > 0 THEN {

		local num_reserve to 0.
		local my_engines to LIST().
		list ENGINES in my_engines.
		for eng in my_engines {
			if NOT eng:FLAMEOUT
			{
				set num_reserve to num_reserve +1.
			}
		}
		print (num_reserve -1) + " Engines left for Staging".
		stage.
		if num_reserve > 0 {
			preserve.
		}
	}
}


function init_autoasparagus {
	global all_engines to LIST().
	list ENGINES in all_engines.
}


// does radial staging when needed. works with solid or liquid fuel engines.
function auto_asparagus {

	for eng in all_engines {
		if eng:STAGE >= STAGE:NUMBER AND eng:FLAMEOUT {

			local teil to ENG:PARENT.

			until teil:NAME = "radialDecoupler" OR NOT teil:HASPARENT {
				set teil to teil:PARENT.
			}
			if teil:NAME = "radialDecoupler" {
				local module to teil:GETMODULE("ModuleAnchoredDecoupler").
				print "Jettison Engine: " + eng:TITLE.
				module:DOEVENT("Decouple").
				init_autoasparagus().
			}
		}

	}
}


// Code from KOS-Utils
function init_autofairing {

set auto_fairing_done to FALSE .

if not (defined ignore_autofairing) { global ignore_autofairing to false.}

 WHEN NOT auto_fairing_done AND NOT ignore_autofairing AND SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.7)  THEN {
		PRINT "Jettisoning Fairings".

        // Iterates over a list of all parts with the stock fairings module
        FOR module IN SHIP:MODULESNAMED("ModuleProceduralFairing") { // Stock and KW Fairings

            // and deploys them
            module:DOEVENT("deploy").
            HUDTEXT("Fairing Utility: Aproaching edge of atmosphere; Deploying Fairings", 3, 2, 30, YELLOW, FALSE).
            PRINT "Deploying Fairings".

        }.

        // Iterates over a list of all parts using the fairing module from the Procedural Fairings Mod
        FOR module IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") { // Procedural Fairings

            // and jettisons them (PF uses the word jettison in the right click menu instead of deploy)
            module:DOEVENT("jettison").
            HUDTEXT("Fairing Utility: Approaching edge of atmosphere; Jettisoning Fairings", 3, 2, 30, YELLOW, FALSE).
            PRINT "Jettisoning Fairings".

        }.

        // Deploying fairings is a one time thing so it disables the module after running it
        SET auto_fairing_done TO TRUE.
		set ignore_autofairing to TRUE.
        PRINT "Fairings Utility disabled".

    }
}.

function init_launch_autofunctions {
	init_autofairing().
	init_autoasparagus().
}
