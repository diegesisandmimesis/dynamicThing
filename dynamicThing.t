#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
dynamicThingModuleID: ModuleID {
        name = 'Dynamic Thing Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// 
class DynamicThingState: Thing
	revealFlag = nil
	order = nil

	check() {
		if(revealFlag == nil)
			return(nil);
		return(gRevealed(revealFlag) == true);
	}
;

class DynamicThing: Thing
	// Unique ID for this instance.  Used as the param name,
	// so if this is 'foozle', then "You see {a foozle/him}. "
	// will work.
	dynamicThingID = nil

	//
	// TITLE FORMATTING STUFF
	//
	// Class to use to handle message param substitutions in
	// "title case".  The default class will work if all the title
	// versions of the name/label are "regular"--they're just the
	// regular name, only with the first letter of each word
	// capitalized.  If there are special cases for aName, theName,
	// and so on, you'll have to create a special class to handle
	// it for this specific DynamicThing instance.
	dynamicThingTitleClass = DynamicThingTitle
	//
	// If skipSmallWords is true, then small words will be ignored
	// when converting the name into title case.
	skipSmallWords = nil
	//
	// The list of small words to use.
	smallWords = static [ 'a', 'an', 'of', 'the', 'to' ]

	//
	// Stuff in this block isn't configurable.  It's mostly
	// values that are computed at runtime.
	//
	// List of all of our states, computed when it's first needed.
	_dynamicThingStateList = nil
	//
	// Used to keep track of when our value changes.
	_dynamicThingLastName = nil

	initializeThing() {
		inherited();
		dynamicThingInit();
	}

	dynamicThingInit() {
		if(dynamicThingID == nil)
			return;
		setGlobalParamName(dynamicThingID);
		dynamicThingInitTitle();
	}

	dynamicThingInitTitle() {
		local obj;

		obj = dynamicThingTitleClass.createInstance();
		obj.dynamicThingInitFromParent(self);
	}

	dynamicThingChanged(v?) {
		if(v == nil)
			v = dynamicThingName();
		return(v != _dynamicThingLastName);
	}

	// Sort the list in ascending order.
	sortDynamicThingStateList() {
		_dynamicThingStateList = _dynamicThingStateList.sort(nil,
			{ a, b: a.order - b.order }
		);
	}

	// Add a state to the list.
	addDynamicThingState(v) {
		local l;

		// Make sure we were passed a valid state.
		if(!v || !v.ofKind(DynamicThingState))
			return(nil);

		// Make sure our state isn't already in the list.
		l = dynamicThingStateList();
		if(l.indexOf(v) != nil)
			return(nil);

		// Add the state, sort the list.
		l.append(v);
		sortDynamicThingStateList();
		
		return(true);
	}

	// Return the state list, creating it if it hasn't already been.
	dynamicThingStateList() {
		// If we already have a list, just return it.
		if(_dynamicThingStateList != nil)
			return(_dynamicThingStateList);

		// We don't already have a list, so create an empty one.
		_dynamicThingStateList = new Vector(16);

		// Now go through our contents and add all our states to
		// the list.
		contents.forEach(function(o) {
			if(o && o.ofKind(DynamicThingState))
				_dynamicThingStateList.append(o);
		});

		// Sort the list
		sortDynamicThingStateList();

		// Return the newly-created list.
		return(_dynamicThingStateList);
	}

	// Get the current state.
	getDynamicThingState() {
		local i, l, st;

		st = nil;
		l = dynamicThingStateList();

		// Check the states.  Order matters;  we return the
		// matching state with the highest order property.
		for(i = 1; i <= l.length(); i++) {
			if(l[i].check() == true)
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
	dynamicThingTitle() {
		return(titleCase(dynamicThingName()));
	}

	dynamicThingName() {
		local st;

		st = getDynamicThingState();
		if(st == nil)
			return(name);
		return(st.name);
	}
	name() { return(dynamicThingName()); }
;

class DynamicThingTitle: Thing
	dynamicThingParent = nil
	name() { return(dynamicThingParent.dynamicThingTitle()); }
	isProperName() { return(dynamicThingParent.isProperName); }
	dynamicThingInitFromParent(obj) {
		if((obj == nil) || !obj.ofKind(DynamicThing))
			return(nil);
		dynamicThingParent = obj;
		setGlobalParamName(obj.dynamicThingID + 'title');
		return(true);
	}
;
