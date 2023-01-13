#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the dynamicThing library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "dynamicThing.h"

versionInfo:    GameID
        name = 'dynamicThing Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the dynamicThing library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the dynamicThing library.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

abstractCave: DynamicThing 'cave';
+defaultState: DynamicThingState 'mysterious cave' 'mysterious cave'
	check() { return(true); }
	order = 0
;
+fooState: DynamicThingState '(secret) hideout' 'Bob\'s secret hideout'
	check() {
		if(gRevealed('bobFlag')) {
			isProperName = true;
			return(true);
		}
		return(nil);
	}
	order = 1
;
+barState: DynamicThingState '(hidden) lair' 'the killer\'s hidden lair'
	check() {
		if(gRevealed('killerFlag')) {
			isProperName = true;
			return(true);
		}
		return(nil);
	}
	order = 2
;
+DynamicThingState '(secret) lair' 'the secret lair of Bob, the killer'
	check() { return(fooState.check() && barState.check()); }
	order = 3
;


// We have to use caveWordAsTitle() in the roomName because (afaik) there
// isn't any way to convert a message param substitution into title case.
caveEntrance:      Room 'Entrance to {a caveTitle/him}'
        "This is the entrance to {a cave/him}.  There's large steel door
	on the north wall with a sign on it. "
	north = caveDoorOutside
;
// The sign that reveals that the cave is Bob's.
+Fixture 'sign' 'sign'
	"The sign says, <q>Bob's Secret Hideout</q>.
	<.reveal bobFlag> "
;
+me: Person;
// The piece of evidence that reveals that the cave is the killer's.
+knife: Thing '(bloody) butcher knife' 'butcher knife'
	"A butcher knife.  The blood on the blade indicates it is
	the murder weapon.
	<.reveal killerFlag> "
;
++bloodOnKnife: Fixture 'blood' 'blood on the knife'
	"It's dried. "
;
+caveKey: Key '(blood) (stained) (blood-stained) brass key' 'brass key'
	"It's a slightly blood-stained brass key. "
;
++bloodOnKey: Fixture 'blood' 'blood on the key'
	"It's dessicated. "
;
+fakeKey: Key '(steel) (nondescript) key' 'steel key'
	"It's a nondescript steel key. "
;
+caveDoorOutside: LockableWithKey, Door 'door' 'door'
	destination = livingRoom
	initiallyLocked = true
	keyList = [ caveKey ]
;

livingRoom: Room 'Living Room In {a caveTitle/him}'
	"This is the living room in {a cave/him}.  A door leads south. "
	south = caveDoorInside
;
+caveDoorInside: Lockable, Door -> caveDoorOutside 'door' 'door';

gameMain: GameMainDef initialPlayerChar = me;
