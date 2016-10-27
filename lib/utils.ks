@LAZYGLOBAL OFF.

function open_terminal {
	CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

	set Terminal:HEIGHT to 72.
	set Terminal:WIDTH to 48.

}

function open_antenna_omni {
	if NOT (defined antennasOpen)
	{
		global antennasOpen to false.
	}
	if NOT antennasOpen {
		FOR antenna IN SHIP:PARTSNAMED("longAntenna")
		{
			print "opening omni antenna".
			antenna:GETMODULE("ModuleRTAntenna"):DOEVENT("Activate").
		}
	}
}

function close_antenna_omni {
	if NOT (defined antennasOpen)
	{
		global antennasOpen to true.
	}
	if antennasOpen {
		FOR antenna IN SHIP:PARTSNAMED("longAntenna")
		{
			print "closing omni antenna".
			antenna:GETMODULE("ModuleRTAntenna"):DOEVENT("Deactivate").
		}
		set antennasOpen to false.
	}
}

function open_servicebay_125 {
	// open the service bay for the solar panels
//	WHEN SHIP:ALTITUDE > 60000 THEN {
		SHIP:PARTSNAMED("ServiceBay.125")[0]:GETMODULE("ModuleAnimateGeneric"):Doevent("Open").
}

function deploy_chutes {
	local chuteList to LIST().
	local partlist to LIST().
	//Gets all of the parts on the craft
	LIST PARTS IN partList.
	FOR item IN partList {
	local moduleList TO item:MODULES.
		FOR module IN moduleList {
			IF module = "RealchuteModule" {
				chuteList:ADD(item).
      }
		}
	}
	FOR chute IN chuteList {
		print "deploying chutes".
		chute:GETMODULE("RealchuteModule"):DOEVENT("Deploy Chute").
	}
}


// returns true if the current state matches the tag from the core
function my_state {
	local parameter my_val.
	local my_string to "__state_" + my_val + "__".
	if CORE:PART:TAG = my_string {
		return true.
	} else {
		return false.
	}
}

function set_next_state {
	local parameter my_val.
	local my_string to "__state_" + my_val + "__".
	set CORE:PART:TAG to my_string.
}

// performs a event by its starting string
function do_event {
	local parameter partmod.
	local parameter evtname.
	for event in partmod:alleventnames {
		if event:startswith(evtname) {
			partmod:doevent(event).
		}
	}
}


// adds a Alarm to KAC.
function add_alarm {
	local parameter alarm_eta,description.
	if ADDONS:KAC:AVAILABLE AND (alarm_eta > 31){

		local my_alarm to ADDALARM("Raw",TIME:SECONDS + alarm_eta - 30, SHIP:NAME + " - Event", description).
		set my_alarm:ACTION to "PauseGame".
		print "Alarm added, go back to KSC".
	}
}
