########
#
# This function watches altitude and conks out the putt=putt when it gets too high.
# 
########

puttPuttStop = func {
    if(getprop("/position/altitude-ft") > 10000) {
        setprop("/controls/APU/putt-putt", 0);
    }
    settimer(puttPuttStop, 20);
}

########
#
# This function starts the putt-putt if it is at a low enough altitude
# Bind it to a command
# 
########

puttPuttStart = func {
    if(getprop("/position/altitude-ft") < 8000) {
        setprop("/controls/APU/putt-putt", 1);
    }
}

########
#
# This function turns the p-brake on and off
#
########

pBrakeCheck = func {
    
    # When attempting to pull handle, check to make sure the pedals are depressed too.  
    if ( !oldPbrakeSetting and getprop("/controls/gear/brake-parking") ) {
        if ( !getprop("/controls/gear/brake-left") or !getprop("/controls/gear/brake-right") ) {
            # Nope. You gotta press both the pedals too. Pop it back out.
            setprop("/controls/gear/brake-parking", 0);
        }      
        # Don't let the handle popping routine touch us yet.
        primedToPop = 0;
    }

    if ( !getprop("/controls/gear/brake-left") and !getprop("/controls/gear/brake-right") ) {
        # OK, now it's ok to pop the handle.
        primedToPop = 1;
    }
    
    # Pop handle when both pedals are touched.
    if ( primedToPop and getprop("/controls/gear/brake-left") and getprop("/controls/gear/brake-right") ) {
        setprop("/controls/gear/brake-parking", 0);
    }

    # Set the real control prop to whatever the handle is now set at.
    setprop("/controls/gear/brake-my-parking", getprop("controls/gear/brake-parking"));
    # Remember it here in case something mucks with the property vaue.
    oldPbrakeSetting = getprop("/controls/gear/brake-parking");
    
    settimer(pBrakeCheck, 0.05);
}

########
#
# This function maintains a property that is used to animate the brake pedals.
#
########

brakePedalAnim = func {
    if ( getprop("/controls/gear/brake-parking") > getprop("/controls/gear/brake-left") ) {
        setprop("/controls/gear/brake-left-rot", getprop("/controls/gear/brake-parking"));
    } else {
        setprop("/controls/gear/brake-left-rot", getprop("/controls/gear/brake-left"));
    }    
    if ( getprop("/controls/gear/brake-parking") > getprop("/controls/gear/brake-right") ) {
        setprop("/controls/gear/brake-right-rot", getprop("/controls/gear/brake-parking"));
    } else {
        setprop("/controls/gear/brake-right-rot", getprop("/controls/gear/brake-right"));
    }

    settimer(brakePedalAnim, 0.05);
}
    
########
#
# This function watches the switch props /controls/lighting/landing-lights-* and sets
# the light props /controls/lighting/landing-light-*-* appropriately. Each switch has
# three mutually exclusive positions: 0,1,2 corresponding to: off, high, down.
#
########

landLightCheck = func {
 
    if(getprop(leftLandLightProp) == 1) {
        setprop(upLeftLandLightProp, 1);
        setprop(downLeftLandLightProp, 0);
    } elsif(getprop(leftLandLightProp) == 2) {
        setprop(upLeftLandLightProp, 0);
        setprop(downLeftLandLightProp, 1);
    } else {
        setprop(upLeftLandLightProp, 0);
        setprop(downLeftLandLightProp, 0);
    }

    if(getprop(rightLandLightProp) == 1) {
        setprop(upRightLandLightProp, 1);
        setprop(downRightLandLightProp, 0);
    } elsif(getprop(rightLandLightProp) == 2) {
        setprop(upRightLandLightProp, 0);
        setprop(downRightLandLightProp, 1);
    } else {
        setprop(upRightLandLightProp, 0);
        setprop(downRightLandLightProp, 0);
    }

    settimer(landLightCheck, 0.25);
}

########
#
# Stole this from Melchior. Thanks Melchior!
#
########

matlist = { # MATERIALS
#                       diffuse             ambient            emission           specular          shi trans
        "lens":         [0.3, 0.3, 0.3,     0.3, 0.3, 0.3,     0.0, 0.0, 0.0,     0.0, 0.0, 0.0,    90, 0],
        "redlight":     [0.0, 0.0, 0.0,     0.0, 0.0, 0.0,     1.0, 0.0, 0.0,     0.0, 0.0, 0.0,    0,  0],
        "greenlight":   [0.0, 0.0, 0.0,     0.0, 0.0, 0.0,     0.0, 1.0, 0.0,     0.0, 0.0, 0.0,    0,  0],
};

apply_mat = func(obj, mat) {
        i = 0;
        base = "/sim/model/b29/material/" ~ obj ~ "/";
        foreach (t; ["diffuse", "ambient", "emission", "specular"]) {
                foreach (c; ["red", "green", "blue"]) {
                        setprop(base ~ t ~ "/" ~ c, mat[i]);
                        i += 1;
                }
        }
        setprop(base ~ "shininess", mat[i]);
        setprop(base ~ "transparency/alpha", 1.0 - mat[i + 1]);
}

########
#
# Check the status of the gear and set lights
# Needs to have /gear/gear[*]/position-norm non-nil
# Also needs lastLightValue[0..2] and checkMasterLight initialised
# lightIndex=0 corresponds to /gear/gear[0] and GearLight0
#
########

newGearLightCheck = func {
}

gearLightCheck = func {
    for (lightIndex=0; lightIndex<3; lightIndex=lightIndex+1) {
        thisObject = "GearLight" ~ lightIndex;
        # Take a gander at the landing gear.
        newValue = getprop("/gear/gear[" ~ lightIndex ~ "]/position-norm");
        # So we don't trigger the following block while the gear is in motion.
        if ((newValue != 1) and (newValue != 0)) {
            newValue = -1;
        }
        # See if things have changed.
        if ( newValue != lastLightValue[lightIndex]) {
	    # And change the lights if they have.
            checkMasterLight=1;
            if ( newValue == 1 ) {
                apply_mat(thisObject, matlist["greenlight"]);
            } elsif ( newValue == 0 ) {
                apply_mat(thisObject, matlist["lens"]);
            } else {
                apply_mat(thisObject, matlist["redlight"]);
            }
            # Remember the current state.
            lastLightValue[lightIndex] = newValue;
        }
    }
    # Set the master light if other lights have changed.
    if (checkMasterLight == 1) {
        if ( (lastLightValue[0]==-1) or (lastLightValue[1]==-1) or (lastLightValue[2]==-1) ) {
            apply_mat("GearLightM", matlist["redlight"]);
        } elsif ( (lastLightValue[0]==1) and (lastLightValue[1]==1) and (lastLightValue[2]==1) ) {
            apply_mat("GearLightM", matlist["greenlight"]);
        } else {
            apply_mat("GearLightM", matlist["lens"]);
        }
        checkMasterLight=0;
    }
    # Rinse, Repeat.
    settimer(gearLightCheck, 0.5);
}

########
#
# Cowl Flaps
#
########

adjustCowlFlaps = func {
    # Figure out what the max safe deployment is.
    if (getprop("/gear/gear/wow") == 1) {
        max = 15;
    } else {
        max = 10;
    }

    # Figure out how much flap we want, and clamp to 0 and 1.
    # We could do the clamping in the animation xml, but iut's easier to just
    # do it once here. Sneak in some intercooler action too.
    setprop(cowlTarget, ((getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")-50)/160));
    if (getprop(cowlTarget) > 1 ) {
        setprop(cowlTarget, 1);
    } elsif (getprop(cowlTarget) < 0 ) {
        setprop(cowlTarget, 0 );
    }
    setprop(cowlTarget, (1-(getprop(cowlTarget)*(max/15))));

    setprop(intercoolerTarget, ((getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")-60)/200));
    if (getprop(intercoolerTarget) > 1 ) {
        setprop(intercoolerTarget, 1);
    } elsif (getprop(intercoolerTarget) < 0 ) {
        setprop(intercoolerTarget, 0 );
    }
    setprop(intercoolerTarget, (1-(getprop(intercoolerTarget))));

    # If the cowls are more than 1 or 1.5 deg off from what we want, kick off an interpolate to fix it
    for (i=0; i<4; i=i+1) {
        if (abs(getprop("/controls/engines/engine[" ~ i ~ "]/cowl-flaps-norm") - getprop(cowlTarget)) > 0.1 ) {
	    interpolate("/controls/engines/engine[" ~ i ~ "]/cowl-flaps-norm",  getprop(cowlTarget), 2.9);
	}
        if (abs(getprop("/controls/engines/engine[" ~ i ~ "]/intercooler-norm") - getprop(intercoolerTarget)) > 0.1 ) {
	    interpolate("/controls/engines/engine[" ~ i ~ "]/intercooler-norm",  getprop(intercoolerTarget), 2.9);
	}
    }

    settimer(adjustCowlFlaps, 3);
}

########
#
# Door functions
#
########

togglecabindoors = func {
    if (getprop("/gear/gear/wow")) {
        b29.tail.toggle();
        b29.pilotwin.toggle();
        b29.copilotwin.toggle();
        b29.hatch.toggle();
    } else {
        b29.tail.close();
        b29.pilotwin.close();
        b29.copilotwin.close();
        b29.hatch.close();
    }
}

########
#
# View functions
#
########

nextPosition = func {
    if (getprop('/sim/current-view/view-number') == 0) {
        if ( (currentPosition+1) < size(positionData) ) {
            currentPosition = currentPosition + 1;
        } else {
            currentPosition = 0;
        }
        setprop('/sim/current-view/x-offset-m',  positionData[currentPosition][1]);
        setprop('/sim/current-view/y-offset-m',  positionData[currentPosition][2]);
        setprop('/sim/current-view/z-offset-m',  positionData[currentPosition][3]);
    }
}

########
#
# Flaps handling
# Flaps switch handling
#
########

controls.flapsDown = func {
    setprop('/sim/model/b29/flap-switch-pos-norm', arg[0]);
    if (arg[0] == 1) {
        if ( getprop('/controls/flight/flaps') < 1 ) {
            interpolate('/controls/flight/flaps', 1, (9*(1-getprop('/controls/flight/flaps'))));
        # } else {
            # check for motor burnout
        }
    } elsif (arg[0] == -1) {
        if ( getprop('/controls/flight/flaps') > 0 ) {
            interpolate('/controls/flight/flaps', 0, (9*getprop('/controls/flight/flaps')));
        # } else {
            # check for motor burnout
        }
    } else {
        interpolate('/controls/flight/flaps');
    }
}

########
#
# Gear switch handling
#
########

gearInit = func {
    setprop('/gear/gear[0]/position-norm', getprop('/controls/gear/gear-down'));
    setprop('/gear/gear[1]/position-norm', getprop('/controls/gear/gear-down'));
    setprop('/gear/gear[2]/position-norm', getprop('/controls/gear/gear-down'));
    setprop('/gear/gear[3]/position-norm', getprop('/controls/gear/gear-down'));

    settimer(waitGearDown, 0);
}

########
#
# Acts as a wrapper script to start/stop the animation handler and
# the function that watches to see when the gear is down and locked.
# It causes gear controls to act as instantaneous switches.
#
########

controls.gearDown = func {
    # Call gear animation handler and spread the word
    moveGear(0, arg[0], 20);
    moveGear(1, arg[0], 30);
    moveGear(2, arg[0], 30);
    moveGear(3, arg[0], 5);
}

########
#
# This is a handler function to tell the FDM when gear is down and locked.
# It get kicked off by the gear init function.
# It watches tha animations to see when to tell the FDM to put the gear down.
#
########

waitGearDown = func {
    p0 = getprop('/gear/gear[0]/position-norm');
    p1 = getprop('/gear/gear[1]/position-norm');
    p2 = getprop('/gear/gear[2]/position-norm');
    p3 = getprop('/gear/gear[3]/position-norm');

    if ((p0==1) and (p1==1) and (p2==1) and (p3==1)) {
        setprop('/controls/gear/gear-down', '1');
    } else {
        setprop('/controls/gear/gear-down', '0');
    }

    settimer(waitGearDown, 0.1);
}

########
#
# This is an animation handler script. commands.gearDown should be overloaded to
# be a wrapper calling this once for each wheel.
# The wheels need to have 0 second transition times for this to work properly.
#
# args: gear_num down/off/up time_delta
#
########

moveGear = func {
    gProp = '/gear/gear['~arg[0]~']/position-norm';

    # Wiggle switch appropriately
    setprop('/sim/model/b29/gear-switch-pos-norm', arg[0]);

    if (arg[1] == 1) {
        # transit gear downward
        if( getprop(gProp) < 1) {
            interpolate(gProp, 1, (arg[2]*(1-getprop(gProp))));
        # } else {
            # check for motor burnout
        }
    } elsif (arg[1] == -1) {
        # transit gear upward
        if( getprop(gProp) > 0) {
            interpolate(gProp, 0, (arg[2]*(getprop(gProp))));
        # } else {
            # check for motor burnout
        }
    } else {
        interpolate(gProp);
    }
}

########
#
# Bombs
#
########

    var bombindex = -1;
    var maxindex = 0;

loadBombs = func {
	# Find out which bomb configuration we are now using and get some important nodes.
	loadoutIndex = getprop('/sim/weapons/current-loadout');
	print('info ', 'Loadout ', loadoutIndex, ' selected');
	loadout =  props.globals.getNode('/sim/weapons/loadout[' ~ loadoutIndex ~ ']');
	weights = props.globals.getNode('/yasim/weights/bomb-bay');

	# Set interleave to the recommended value for this loadout.
	setprop('/sim/weapons/interleave-sec', loadout.getChild('interleave-sec').getValue());

	# Delete any YASim weights.
	foreach (bombRack; weights.getChildren('rack')) {
		bombRack.setDoubleValue(0);
	}

	# Set all the bomb triggers, and assign the proper weights for YASim.
	foreach (bomb; loadout.getChildren('bomb')) {
		# Triggers
		dropped = bomb.getNode('dropped');
		dropped.setBoolValue(0);
		# Weights
		rackIndex = (bomb.getNode('rack').getValue() - 1);
		weight = bomb.getNode('weight');
		bombRack = weights.getChild('rack', rackIndex);
		bombRack.setDoubleValue(bombRack.getValue() + weight.getValue());
		print('info ', 'Rack ', rackIndex, ' now: ', (bombRack.getValue()));
	}

    if (loadoutIndex != 0){
        bombindex = -1;
        maxindex = bomb.getIndex();
        print ("min index", bombindex, "max index ", maxindex);
    }
}

dropBombs = func (){

#    Check if we still need to do anything
        if (!getprop('/controls/armament/release-all') or 
            !getprop('/sim/model/doors/bombbay/position-norm')) {
            bombindex = 0;
            print('alert ', 'release stopped');
            return;
        }

    print('info ', ' Dropping bombs ');

    dropBomb = func (bomb, weights) {
        var dropped = bomb.getNode('dropped');
        print ("Index: ", bomb.getIndex());
        if (! dropped.getValue()) {
            var weight = bomb.getNode('weight');
            var rackIndex = (bomb.getNode('rack').getValue() - 1);
            var bombRack = weights.getChild('rack', rackIndex);
            bombRack.setDoubleValue(bombRack.getValue() - weight.getValue());
            dropped.setBoolValue(1);
            print('info ', 'Dropping bomb ', bomb.getIndex());
        } else {
            print('warn ', 'Dropping unloaded bomb ', bomb.getIndex(), ' failed');
        }
    }

    var loadoutIndex =  getprop('/sim/weapons/current-loadout');
    var loadout =  props.globals.getNode('/sim/weapons/loadout[' ~ loadoutIndex ~ ']');
    var weights = props.globals.getNode('/yasim/weights/bomb-bay');
    var interleave = getprop('/sim/weapons/interleave-sec');

    var selectBomb = func(){

        foreach (var bomb; loadout.getChildren('bomb')) {

            if ( bombindex == bomb.getIndex() ){
                print('info ', ' Selecting bomb ', bomb.getIndex());
                dropBomb(bomb, weights);
#            break;
            }

        }

    }

    bombindex += 1; 
    print('info ', 'Seqencing bombs ', bombindex, " interleave ", interleave );

    if (bombindex <= maxindex){
        print('info ', 'Seqenced bomb ', bombindex);
        selectBomb(bombindex);
        settimer(dropBombs, interleave);
    }else{
        # Done - set control back to off 
        setprop('/controls/armament/release-all', 0);
    }


}# end dropBombs





print("impacts init ...");
var impact_node = props.globals.getNode("sim/ai/aircraft/impact/M47", 1);

var impacts = func(n) {
	var impact = impact_node.getValue();
	var node = props.globals.getNode(n.getValue(), 1);
	print ("impact ", impact, " lon " , node.getNode("impact/longitude-deg").getValue(),);
	geo.put_model("/Aircraft/b29/Models/wildfire.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.25,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
}

########
#
# View
#
########

adjustViewTarget = func {
	maxD   = getprop('sim/current-view/target-z-offset-max-m');
	minD   = getprop('sim/current-view/target-z-offset-min-m');
	fovMin = getprop('sim/current-view/field-of-view-min');
	fovMax = getprop('sim/current-view/field-of-view-max');
	fov    = getprop('sim/current-view/field-of-view');
	bays   = getprop('sim/model/doors/bombbay/position-norm');
	if ( bays ) {
		setprop('sim/current-view/target-z-offset-m', 10.5);
	} else {
		if ( fov < fovMin ) {
			setprop('sim/current-view/target-z-offset-m', minD);
		} elsif ( fov <= fovMax ) {
			setprop('sim/current-view/target-z-offset-m', minD+(maxD-minD)*(fov-fovMin)/(fovMax-fovMin));
		} else {
			setprop('sim/current-view/target-z-offset-m', maxD);
		}
	}
}

########
#
# Hobbs Meter
#
########

    updateHobbs = func{
        var running = engine_running_Node.getValue();

        if(running){
            hobbs_engine.start();
        } else {
            hobbs_engine.stop();
        }

        settimer(updateHobbs,0)
    }

########
#
# contrail calculator. Based on an approxmation to the "Appleman Chart"
# y = -0.077x2 + 2.7188x - 64.36
#
########

    updateContrail = func{
        var x = pressure_Node.getValue();
        var y = temperature_Node.getValue();
        var con_temp = -0.077 * x * x + 2.7188 * x - 64.36;
        contrail_temp_Node.setValue(con_temp);

        if (y < con_temp and y < -40){
            contrail_Node.setValue(1);
        } else {
            contrail_Node.setValue(0);
        }

        settimer(updateContrail,30)
    }

########
#
# Init section
#
########

    ### Landing lights
    # Switch position
    leftLandLightProp = "/controls/lighting/landing-lights-left";
    rightLandLightProp = "/controls/lighting/landing-lights-right";
    # High beams
    upLeftLandLightProp = "/controls/lighting/landing-light-up-left";
    upRightLandLightProp = "/controls/lighting/landing-light-up-right";
    # Downward lights
    downLeftLandLightProp = "/controls/lighting/landing-light-down-left";
    downRightLandLightProp = "/controls/lighting/landing-light-down-right";
    # Init switches to any pre-existing landing light default.
    setprop(leftLandLightProp, getprop("/controls/lighting/landing-lights"));
    setprop(rightLandLightProp, getprop("/controls/lighting/landing-lights"));
    settimer(landLightCheck, 0);

    ### Nav lights
    # Init switches to any pre-existing nav light default.
    setprop("/controls/lighting/tail-nav-lights", getprop("/controls/lighting/nav-lights"));
    setprop("/controls/lighting/wingtip-nav-lights", getprop("/controls/lighting/nav-lights"));

    ### Putt Putt
    settimer(puttPuttStop, 0);

    ### Parking brake and brake pedals
    # Set the *real* parking brake prop. brake-parking is only used for the handle.
    setprop("/controls/gear/brake-my-parking", getprop("/controls/gear/brake-parking"));
    oldPbrakeSetting = getprop("/controls/gear/brake-parking");
    primedToPop = 0;
    settimer(pBrakeCheck, 0);
    settimer(brakePedalAnim, 0);

    # Doors
    bombbay = aircraft.door.new("sim/model/doors/bombbay", 1.5);
    tail = aircraft.door.new("sim/model/doors/tail", 0.75);
    hatch = aircraft.door.new("sim/model/doors/hatch", 0.5);
    pilotwin = aircraft.door.new("sim/model/doors/pilotwin", 1.75);
    copilotwin = aircraft.door.new("sim/model/doors/copilotwin", 1.75);

    ### Gear indicator lights
    for (i=0; i<3; i=i+1) {
        if (getprop("/gear/gear[" ~ i ~ "]/position-norm") == nil) {
            setprop("/gear/gear[" ~ i ~ "]/position-norm", 0);
        }
    }
    lastLightValue = [0,0,0];
    checkMasterLight=1;
    settimer(gearLightCheck, 0);

    ### Cowl flaps and intercoolers -- Move to crew.nas
    # Since the FDM can be a little slow out of bed, and we need this set ...
    if (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") == nil) {
        setprop("instrumentation/airspeed-indicator/indicated-speed-kt", 0);
    }
    cowlTarget="/controls/engines/cowl-target";
    intercoolerTarget="/controls/engines/intercooler-target";
    for (i=0; i<4; i=i+1) {
        setprop("/controls/engines/engine[" ~ i ~ "]/cowl-flaps-norm", 0);
        setprop("/controls/engines/engine[" ~ i ~ "]/intercooler-norm", 0);
    }
    settimer(adjustCowlFlaps, 0);

    ### Interior view data
    currentPosition = 0;
    positionData = [
    ["Pilot"      , -0.67,  0.9,  2.3],
    ["Co-pilot"   ,  0.67,  0.9,  2.3],
    ["Bombadier"  ,     0,  0.4,  0.9],
    ];

    ### Gear
    # Since we are controling position-norm instead of YASim, we have to init it.
    settimer(gearInit, 0);

    ### Bombs
    setlistener("/sim/ai/aircraft/impact/M47", impacts);
    setlistener("/sim/weapons/current-loadout", loadBombs);
    setlistener("/controls/armament/release-all", dropBombs);
    settimer(loadBombs, 0);

    ### View
    # setlistener("sim/current-view", foo);
    setlistener("sim/current-view/field-of-view", adjustViewTarget);
    setlistener("sim/current-view/view-number", adjustViewTarget);
    setlistener("sim/model/doors/bombbay/position-norm", adjustViewTarget);

    ###  Engine Hobbs Meter 

    var hobbs_engine = aircraft.timer.new("sim/time/hobbs/engine[0]", 60, 0);
    var engine_running_Node = props.globals.initNode("engines/engine[0]/running", 1, "BOOL");

    hobbs_engine.reset();
    updateHobbs();

    ### Contrail
    
    var pressure_Node = props.globals.initNode("environment/pressure-inhg", 1, "DOUBLE");
    var temperature_Node = props.globals.initNode("environment/temperature-degc", 1, "DOUBLE");
    var contrail_Node = props.globals.initNode("environment/contrail", 1, "BOOL");
    var contrail_temp_Node = props.globals.initNode("environment/contrail-temperature-degc", 1, "DOUBLE");
    updateContrail();

