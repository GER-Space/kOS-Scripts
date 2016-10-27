//@LAZYGLOBAL OFF.

wait 2.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

set Terminal:HEIGHT to 40.
set Terminal:WIDTH to 48.

//switch to script
print "Waiting for Orders".

wait until NOT SHIP:MESSAGES:EMPTY.

SET RECEIVED TO SHIP:MESSAGES:POP.
PRINT "Trying to run " + RECEIVED:CONTENT + " from vessel " + RECEIVED:SENDER:NAME.
runpath (RECEIVED:CONTENT,RECEIVED:SENDER:NAME).
