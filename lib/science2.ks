
// adds the science Modules to the queue structure
function do_science_init {
//	local parameter what.

	global l_science to lexicon().

	// list all science modules in one big list.
	local all_modules to list().
	set all_modules to SHIP:modulesnamed("DMModuleScienceAnimate").
	for my_mod in SHIP:modulesnamed("ModuleScienceExperiment") { all_modules:add(my_mod). }.

	//
	global sc_identifiers to list(
	"log temperature",
	"log pressure data",
	"observe materials bay",
	"observe mystery goo",
	"log gravity data",
	"log seismic data",
	"log atmospheric data",
	"log radio plasma wave data",
	"log irradiance scan",
	"log magnetometer data",
	"eva report",
	"crew report",
	"take surface sample").

	for my_key in sc_identifiers {
		l_science:ADD(my_key,QUEUE()).
	}
	local q_tmp to QUEUE().
	for my_mod in all_modules {
		for my_key in sc_identifiers {
			if my_mod:HASDATA { break. }
			if (my_mod:ALLACTIONNAMES:CONTAINS(my_key)) {

				set q_tmp to l_science[my_key] .
				q_tmp:PUSH(my_mod).
				set l_science[my_key] to q_tmp.
			}

		}
	}

}

function do_science {
	local parameter my_key.
	local parameter do_trans to false.

	if (NOT l_science:HASKEY(my_key)) { print "Experiment not found" . return 0.}


	if l_science[my_key]:LENGTH = 0 {
		print "No more free Science Experiments found".
		return 0.
	}

	local my_mod to l_science[my_key]:PEEK.
	my_mod:deploy().

	local starttime to time:seconds.
	wait until (my_mod:hasdata) or (time:seconds > starttime + 20) .

	if (do_trans) AND (my_mod:hasdata) {
		print "Transmitting data".
		my_mod:transmit.
		wait 10.
	}
	if (NOT ((do_trans) AND (my_mod:RERUNNABLE)))  {
		// if we don't send, then remove the Experiment
		l_science[my_key]:POP.
	}
	return my_mod.
}



function do_science_transmit {
	local parameter my_key.

	return do_science(my_key,true).

}




do_science_init().
