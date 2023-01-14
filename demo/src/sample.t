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

// Creates an abstract cave object that can be referenced via
// something like "This is {a cave/him}. " and "Entrance to {a caveTitle/him}".
abstractCave: DynamicThing 'cave';
//
// List of states for the DynamicThing.
// template is
//
//	DynamicThingState 'VOCABULARY' 'NAME' +ORDER 'REVEAL_KEY'
//
// ...where
//
//		VOCABULARY is the vocabulary for the state.  the format is
//			identical to the template for a normal Thing
//		NAME is the name for the state.  it also uses the same format
//			as a normal Thing
//		ORDER is an optional numeric value used to order the states.
//			the state with the highest order whose check method
//			returns true will be used
//		REVEAL_KEY is an optional string to test with gReveal().  only
//			used if no explicit dtsCheck() method is defined in
//			the state declaration.
//
// The dtsCheck() method is called for each state and the one with the highest
// numeric order whose check method returns true is the active state.
//
// DynamicThingStateDefault is a convenience class that defines a dtsCheck()
// method that always returns true and an order of 0.
+DynamicThingStateDefault 'mysterious cave' 'mysterious cave';
//
// This state defines an order of 1 and its check method will return true
// when gRevealed('bobFlag') is true.
// isProperName is set to true so "{a cave/him}" will evaluate to
// "Bob's secret hideout" instead of "a Bob's secret hideout".
+fooState: DynamicThingState
	'(secret) hideout' 'Bob\'s secret hideout' +1 'bobFlag'
	isProperName = true
;
//
// Mechanically the same as the above state.
+barState: DynamicThingState
	'(hidden) lair' 'the killer\'s hidden lair' +2 'killerFlag'
	isProperName = true;
;
//
// A final state for when both flags are set.
// For this we don't define a flag for to check with gRevealed() and
// instead we provide our own dtsCheck() method.
// We assign the two states immediately above to variables entirely
// so we can check them here.  Note that the first (default) and last (this)
// state don't bother to do this.
+DynamicThingState '(secret) lair' 'the secret lair of Bob, the killer' +3
	isProperName = true
	dtsCheck() {
		return(fooState.dtsCheck() && barState.dtsCheck());
	}
;


// We use {caveTitle} in the room name to get the state name in title
// case (first letter of every word capitalized).  In the room description
// we use {cave} to get the "normal" version of the name.
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
