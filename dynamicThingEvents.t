#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include "reflect.t"

#ifdef DYNAMIC_THING_EVENTS

// Class to hold a concept state update.
// Used to pass the old state and new state to event handlers.
class ConceptUpdate: object
	oldState = nil
	newState = nil

	construct(v0?, v1?) {
		oldState = (v0 ? v0 : nil);
		newState = (v1 ? v1 : nil);
	}
;

// Changes to Concept that allow DynamicThing instances to subscribe
// to state change notifications.
modify Concept
	// The current DynamicThingState.
	_conceptStateCurrent = nil

	// Returns true if the given arg doesn't match the
	// current state.
	conceptChanged(v?) { return(v != _conceptStateCurrent); }

	// Modify existing Concept.getgetConceptState() to save
	// the current state and call the event hander(s) when it changes.
	getConceptState() {
		local v0, v1;

		v0 = _conceptStateCurrent;
		v1 = inherited();
		if(v0 != v1) {
			conceptNotify(v0, v1);
			_conceptStateCurrent = v1;
		}

		return(v1);
	}

	// Basic notification script.
	// Instances might want to do more elaborate stuff in here, but
	// remember to add inherited() or DynamicThings won't get updated.
	conceptNotify(v0, v1) {
		notifySubscribers('conceptChange', new ConceptUpdate(v0, v1));
	}
;

// A class for objects whose vocabulary is automagically updated to
// reflect the current state of a specified Concept.
// Note that the vocabulary of a DynamicThing is a combination of both
// whatever it's declared as AND the current concept state.  E.g.
//
//	caveKey: Key, DynamicThing '(small) (brass) key' 'brass key'
//		"It's a small brass key. "
//		dynamicThingConcept = mine
//	;
//	mine: Concept 'mine';
//	+ConceptStateDefault '(abandoned) mine' 'abandoned mine';
//	+ConceptState '(King) (Solomon\'s) mine' 'King Solomon\'s mine'
//		+1 'kingFlag'
//		isProperName = true
//	;
//
// ...will always match >X BRASS KEY, and will additionally match
// >X ABANDONED MINE KEY initially and >X SOLOMON'S MINE KEY if the
// gRevealed('kingFlag') returns true.
//
class DynamicThing: EventListener
	// Concept instance whose states we'll use to update our vocabulary.
	dynamicThingConcept = nil

	// An optional preposition to add to our vocabulary.
	// If we're a "map" and our concept is an "abandoned mine" that
	// becomes at some point "King Solomon's mine", then if we define
	// dynamicThingPrep = 'to' we'll get "map to the abandoned mine" and
	// "map to King Solomon's mine" as appropriate.
	// The value can also be a list, i.e.
	// dynamicThingPrep = static [ 'to', 'from' ]
	dynamicThingPrep = nil

	// Only update the vocabulary when this is true.
	// NOTE:  Just setting this to true doesn't in and of itself update
	//	  the vocabulary, so be sure to use setDynamicThingReady(true)
	//	  to toggle this on if it starts out nil.
	dynamicThingReady = true

	// If true, we remove the vocabulary associated with the old state
	// when we change states.
	// Off by default so as to not confuse players.
	dynamicThingResetOnUpdate = nil

	initializeThing() {
		inherited();
		initializeDynamicThingEventListener();
		initializeDynamicThingVocab();
	}

	// Add "empty" prepositions (if configured to do so).
	initializeDynamicThingVocab() {
		dynamicThingAddPrepositions(nil);
	}

	// Add subscribe to our concept for updates.
	initializeDynamicThingEventListener() {
		if((dynamicThingConcept == nil)
			|| !dynamicThingConcept.ofKind(Concept))
			return;
		dynamicThingConcept.addSubscriber(self,
			&dynamicThingEventHandler, 'conceptChange');
	}

	// Remove the old state's vocabulary.
	dynamicThingRevertVocab(data) {
		local str;

		// Only reset if we're configured to.
		if(dynamicThingResetOnUpdate != true)
			return(nil);

		// Make sure we got a valid state as an argument.
		if((data == nil) || !data.ofKind(ConceptState))
			return(nil);

		// Remove the concept's adjectives and nouns from our
		// adjective list.
		cmdDict.removeWord(self, data.adjective, &adjective);
		cmdDict.removeWord(self, data.noun, &adjective);

		// Now, if we have a preposition defined, remove the
		// vocabulary associated with it.
		// This is superfluous unless the concept state's
		// theName is "custom"...if it isn't then we'll have
		// caught everything above.
		// We DON'T remove the preposition itself, because
		// if we accept e.g. "the key to the foozle" then
		// we probably still want to understand the
		// construction "the key to the..." even if "foozle"
		// is now invalid.  That gets us a "You don't see..."
		// failure message, instead of a "The story doesn't
		// understand..." message, which is presumed to be
		// the correct behavior.
		if(dynamicThingPrep != nil) {
			str = cmdTokenizer.tokenize(data.theName);
			if(str) {
				str.forEach(function(o) {
					if(o.length != 3) return;
					cmdDict.removeWord(self, o[3],
						&adjective);
				});
			}
		}

		// Do our post-change cleanup hygiene, even though it
		// *probably* isn't necessary because we just removed
		// stuff.
		dynamicThingVocabCleanup();

		return(true);
	}

	// Update our vocabulary to reflect our concept's current state.
	dynamicThingUpdateVocab(data) {
		// If we're not ready, we don't update.
		if(dynamicThingReady != true)
			return(nil);

		// Make sure the argument we got it valid.
		if((data == nil) || !data.ofKind(ConceptState))
			return(nil);

		// Reset our vocabulary.  Mostly a hook for instances
		// to use if they have one-off stuff to do on a
		// vocabulary change.
		dynamicThingVocabReset();

		// Add the ConceptState's adjectives and nouns to our
		// dictionary.
		cmdDict.addWord(self, data.adjective, &adjective);
		cmdDict.addWord(self, data.noun, &adjective);

		// The addWord() stuff above will get us most of the way to
		// where we're going:  if we're a 'key' and the concept state
		// we're adding vocabulary for are the 'ancient ruins' then
		// with the above >X THE ANCIENT RUINS KEY will work as
		// expected.  But if we also want
		// >X THE KEY TO THE ANCIENT RUINS to work, then we need to add
		// all the prepositions we want to work AS WELL AS THE ARTICLES.
		// If we don't add 'the' as an adjective,
		// >X THE KEY TO ANCIENT RUINS would work but
		// >X THE KEY TO THE ANCIENT RUINS would fail.
		dynamicThingAddPrepositions(data);

		dynamicThingVocabCleanup();
		
		return(true);
	}

	// By default we do nothing;  instances can do elaborate
	// juggling here if necessary (e.g., if there's overlap between
	// the vocabulary on the "stock" object and one or more
	// concept states it uses).
	dynamicThingVocabReset() {}

	// Some minimal housekeeping to try to keep our vocabulary
	// reasonably neat.
	dynamicThingVocabCleanup() {
		local idx;

		// First of all, make sure all our tokens are only
		// in their respective lists once.  Having them occur
		// multiple times doesn't break anything, but we don't
		// want a situation where something we're doing causes
		// the list sizes to grow without bounds.
		adjective = adjective.getUnique();
		noun = noun.getUnique();
		weakTokens = weakTokens.getUnique();

		// Now we make sure none of our nouns are listed as weak
		// tokens.  This is because a vocab string like
		// '(pebble) pebble' will produce vocabulary that never
		// matches.
		// We check for this when we add weak tokens ourselves,
		// so the only way this could happen is in object declarations
		// (probably due to a typo/thinko) or when we change to a
		// state using a noun that is already in our weak tokens.
		noun.forEach(function(o) {
			idx = weakTokens.indexOf(o);
			if(idx == nil)
				return;
			weakTokens = weakTokens.removeElementAt(idx);
		});
	}

	// Try to add whatever prepositional phrases we've been asked to add.
	dynamicThingAddPrepositions(data) {
		local l;

		// If we have no prepositions defined, we have nothing to do.
		if(dynamicThingPrep == nil)
			return;

		// If our prep list isn't a list, make it one.
		if(dataType(dynamicThingPrep) == TypeList)
			l = dynamicThingPrep;
		else
			l = [ dynamicThingPrep ];

		// Go through the list, adding all the prepositions.
		l.forEach(function(o) {
			_dynamicThingAddPreposition(o, data);
		});

		// We also need to add our own nouns as adjectives.  If we
		// don't, then the ungrammatical >X TO THE ANCIENT RUINS
		// would work but NOT >X KEY TO THE ANCIENT RUINS
		cmdDict.addWord(self, noun, &adjective);
	}

	// Add a weak token, iff it isn't already part of our noun list.
	_dynamicThingAddWeakToken(v) {
		if(self.noun.indexOf(v) != nil)
			return;
		weakTokens += v;
	}

	// Add the vocabulary for a single preposition (first arg).
	_dynamicThingAddPreposition(prep, data) {
		local str;

		// Create a string containing the preposition we're handling
		// and the name of the state we're adding vocabulary for.
		// So if prep is 'from' and the name of the concept state is
		// 'underground golf course' then we'll get a parsed array
		// of tokens for 'from the underground golf course'.
		if(data == nil)
			// First time we're called, at startup, we just
			// want to add the preposition so that the failure
			// messages are a little less misleading
			// ("You see no..." instead of "The story doesn't
			// understand...").
			str = [[prep, nil, prep], ['the', nil, 'the']];
		else 
			str = cmdTokenizer.tokenize(prep + ' ' + data.theName);

		// Now we add each of the tokens we got above as an adjective
		// in our dictionary.
		str.forEach(function(o) {
			if(o.length != 3) return;
			cmdDict.addWord(self, o[3], &adjective);
			_dynamicThingAddWeakToken(o[3]);
		});
	}

	// Event handler that is notified whenever the concept's
	// state changes.
	dynamicThingEventHandler(obj?) {
		if((obj == nil) || !obj.ofKind(EventHandlerEvent))
			return;
		if((obj.data == nil) || !obj.data.ofKind(ConceptUpdate))
			return;
		dynamicThingRevertVocab(obj.data.oldState);
		dynamicThingUpdateVocab(obj.data.newState);
	}

	// Method to change our ready state.
	// We have to do this (instead of just throwing a conditional
	// statement in dynamicThingReady itself) because the vocabulary
	// can change as a result of this, so we have to call the update
	// method to apply the change.
	setDynamicThingReady(v?) {
		dynamicThingReady = v;
		if(dynamicThingReady)
			dynamicThingUpdateVocab(dynamicThingConcept
				._conceptStateCurrent);
	}
;

#else // DYNAMIC_THING_EVENTS

// Define a placeholder to degrade more gracefully.
class DynamicThing: Thing;

#endif // DYNAMIC_THING_EVENTS
