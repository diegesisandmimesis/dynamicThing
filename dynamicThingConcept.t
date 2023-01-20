#charset "us-ascii"
//
// dynamicThingConcept.t
//
// Definition of the Concept and ConceptState classes.  These are for
// abstract, knowledge-based ideas that link multiple objects, locations,
// and persons together.
//
// Say there's a location that starts out idenfied as a "an overgrown field",
// in which the player discovers a stone tablet.  This is "the tablet found
// in the overgrown field".  Then the player digs around a little, and
// discovers there's an ancient ruin under the field.  Then the location is
// "an ancient ruin" and the object is "the tablet found in the ancient ruin".
// If the player talks to Alice, they are told the ruins are a neolitic temple.
// Bob, on the other hand, suggests it's UFO landing site.  So now maybe
// we want the item to be "the tablet found in the neolithic temple" or
// "the tablet found in the UFO landing site".
//
// This is possible via a bunch of spaghetti code in individual objects, which
// could get out of hand if there are a lot of them.  The idea of this
// module is to provide a mechanism for encapsulating all the logic for this
// sort of thing in a single object (and states for it), which other objects
// can then refer to, to update their descriptions, labels, vocabulary, and so
// on automagically.
#include <adv3.h>
#include <en_us.h>

#include "dynamicThing.h"

// Class for the concept states.  Each state represents one possible
// "interpretation" of the abstract thing represented by the Concept they
// apply to.
class ConceptState: Thing
	// If conceptRevealKey is defined, then this state's check method
	// will return true if gRevealed(conceptRevealKey) returns true.
	conceptRevealKey = nil
	
	// A priority for this state.  States are evaluated in ascending order,
	// with the highest-order one whose check method returns true becomming
	// the new active state.
	conceptOrder = 99

	// Check method for this state.  Returns true if the state is
	// eligible to become active, nil otherwise.
	// By default this just checks the conceptRevealKey, if any,
	// but instances can overwrite this with whatever they want.
	conceptCheck() {
		if(conceptRevealKey == nil)
			return(nil);
		return(gRevealed(conceptRevealKey) == true);
	}

	initializeThing() {
		inherited();
		conceptFixOrder();
	}

	// Make sure we have numeric values for the order property.
	conceptFixOrder() {
		switch(dataTypeXlat(conceptOrder)) {
			case TypeSString:
				conceptOrder = toInteger(conceptOrder);
				break;
			case TypeInt:
				break;
			default:
				conceptOrder = 99;
				break;
		}
	}
;

// If we're compiling with suport for event notifications, we make
// Concept instances event sources.
// There's more stuff we do for event handling, but it lives in a giant
// preprocessor block in its own source file, dynamicThingEvents.t.
#ifdef DYNAMIC_THING_EVENTS
class Concept: Thing, EventNotifier
#else // DYNAMIC_THING_EVENTS
class Concept: Thing
#endif // DYNAMIC_THING_EVENTS
	// Unique ID for this instance.  Used as the param name,
	// so if this is 'foozle', then "You see {a foozle/him}. "
	// will work.
	conceptID = nil

	//
	// TITLE FORMATTING STUFF
	//
	// Class to use to handle message param substitutions in
	// "title case".  The default class will work if all the title
	// versions of the name/label are "regular"--they're just the
	// regular name, only with the first letter of each word
	// capitalized.  If there are special cases for aName, theName,
	// and so on, you'll have to create a special class to handle
	// it for this specific Concept instance.
	conceptTitleClass = ConceptTitle
	//
	// If skipSmallWords is true, then small words will be ignored
	// when converting the name into title case.
	// This probably wants to be set to true unless you're planning
	// on wrestling with it:  if you're using message parameter
	// substitution to access the state names, they'll use aName,
	// theName and so on under the hood, and they'll always return
	// articles and so on in lower case.
	skipSmallWords = true
	//
	// The list of small words to use.
	smallWords = static [ 'a', 'an', 'of', 'the', 'to' ]

	//
	// Stuff in this block isn't configurable.  It's mostly
	// values that are computed at runtime.
	//
	// List of all of our states, computed when it's first needed.
	_conceptStateList = nil

	initializeThing() {
		inherited();
		conceptInit();
	}

	conceptInit() {
		if(conceptID == nil)
			return;

		// Set up our message param substitution string.
		setGlobalParamName(conceptID);

		// Set up the substitution stuff for the title.
		conceptInitTitle();
	}

	// To handle titles (for e.g. room names) we create a separate
	// object that refers back to us.  This is mostly just to allow
	// the other instance to have a different message parameter
	// substitution string.
	// (You can define multiple message param substitution strings
	// for a single object, but the library will use obj.name, 
	// obj.theName, and so on, and there isn't any way to configure
	// this.  Since our methods don't have any practical way to tell
	// who their caller is, we end up creating a different object whose
	// name, theName, and so on will return the same stuff as ours
	// does, only in title case.
	conceptInitTitle() {
		local obj;

		obj = conceptTitleClass.createInstance();
		obj.conceptInitFromParent(self);
	}

	// Sort the list in ascending order.
	sortConceptStateList() {
		_conceptStateList = _conceptStateList.sort(nil,
			{ a, b: a.conceptOrder - b.conceptOrder }
		);
	}

	// Add a state to the list.
	addConceptState(v) {
		local l;

		// Make sure we were passed a valid state.
		if(!v || !v.ofKind(ConceptState))
			return(nil);

		// Make sure our state isn't already in the list.
		l = conceptStateList();
		if(l.indexOf(v) != nil)
			return(nil);

		// Add the state, sort the list.
		l.append(v);
		sortConceptStateList();
		
		return(true);
	}

	// Return the state list, creating it if it hasn't already been.
	conceptStateList() {
		// If we already have a list, just return it.
		if(_conceptStateList != nil)
			return(_conceptStateList);

		// We don't already have a list, so create an empty one.
		_conceptStateList = new Vector(16);

		// Now go through our contents and add all our states to
		// the list.
		contents.forEach(function(o) {
			if(o && o.ofKind(ConceptState))
				_conceptStateList.append(o);
		});

		// Sort the list
		sortConceptStateList();

		// Return the newly-created list.
		return(_conceptStateList);
	}

	// Get the current state.
	getConceptState() {
		local i, l, st;

		st = nil;
		l = conceptStateList();

		// Check the states.  Order matters;  we return the
		// matching state with the highest order property.
		for(i = 1; i <= l.length(); i++) {
			if(l[i].conceptCheck() == true)
				st = l[i];
		}

		return(st);
	}

	// Rewrite the passed string as a title:  capitalizes the first
	// letter of each word, optionally skipping a defined set of "small
	// words" (the, of, and so on) that occur in the middle of the string.
	// This is a *very* slight variation of sample code in the tads-gen
	// documentation (from which we get rexReplace()).
	titleCase(txt) {
		if(!txt) return('');
		return(rexReplace('%<(<alphanum|squote>+)%>', txt,
			function(s, idx) {
				// Skip capitalization if:  a)  the
				// skipSmallWords flag is set, b)  we're not
				// at the very start of the string, and
				// c)  we're in the list of skippable
				// words.
				if((skipSmallWords == true) && (idx > 1) &&
					smallWords.indexOf(s.toLower()) != nil)
					return(s);

				// Capitalize the first letter.
				return(s.substr(1, 1).toTitleCase()
					+ s.substr(2));
			}, ReplaceAll)
		);
	}

	// Return the word formatted for use as a title, e.g. in a room name.
	conceptTitle() {
		return(titleCase(conceptName()));
	}

	isProperName() {
		local st;

		st = getConceptState();
		if(st == nil)
			return(nil);
		return(st.isProperName());
	}

	conceptName() {
		local st;

		st = getConceptState();
		if(st == nil)
			return(name);
		return(st.name);
	}
	name() { return(conceptName()); }
;

// Utility class that exists entirely to handle the title case for
// the parent Concept.
class ConceptTitle: Thing
	conceptParent = nil
	name() { return(conceptParent.conceptTitle()); }
	isProperName() { return(conceptParent.isProperName); }
	conceptInitFromParent(obj) {
		if((obj == nil) || !obj.ofKind(Concept))
			return(nil);
		conceptParent = obj;
		setGlobalParamName(obj.conceptID + 'title');
		return(true);
	}
;

// Convenience class for declaring default states.
class ConceptStateDefault: ConceptState
	conceptCheck() { return(true); }
	conceptOrder = 0
;
