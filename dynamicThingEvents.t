#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include "reflect.t"

#ifdef DYNAMIC_THING_EVENTS

modify Concept
	// The current DynamicThingState
	_conceptStateCurrent = nil

	// Returns true if the given arg doesn't match the
	// current state.
	conceptChanged(v?) { return(v != _conceptStateCurrent); }

	// Modify existing DynamicThing.getDynamicThingState() to save
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

	// Stub notification script.
	conceptNotify(v0, v1) {
		notifySubscribers('conceptChange', v1);
	}
;

class DynamicThing: EventListener
	// Concept instance whose states we'll use to update our vocabulary.
	dynamicThingConcept = nil

	dynamicThingPrep = nil
	//dynamicThingAddTo = nil

	// Same as above, only for "from".
	dynamicThingAddFrom = nil

	// Only update the vocabulary when this is true.
	// NOTE:  Just setting this to true doesn't in and of itself update
	//	  the vocabulary, so be sure to use setDynamicThingReady(true)
	//	  to toggle this on if it starts out nil.
	dynamicThingReady = true

	initializeThing() {
		inherited();
		initializeDynamicThingEventListener();
	}

	initializeDynamicThingEventListener() {
		if((dynamicThingConcept == nil)
			|| !dynamicThingConcept.ofKind(Concept))
			return;
		dynamicThingConcept.addSubscriber(self,
			&dynamicThingEventHandler, 'conceptChange');
	}

	dynamicThingUpdateVocab(data) {
		if(dynamicThingReady != true)
			return(nil);

		// Make sure the argument we got it valid.
		if((data == nil) || !data.ofKind(ConceptState))
			return(nil);

		// Just reset our vocabulary.
		initializeVocab();

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

		self.adjective = self.adjective.getUnique();
		self.noun = self.noun.getUnique();
		self.weakTokens = self.weakTokens.getUnique();
		
		return(true);
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
	_dynamicThingAddWeakToken(v) {
		if(self.noun.indexOf(v) != nil)
			return;
		weakTokens += v;
	}
	_dynamicThingAddPreposition(prep, data) {
		local str;

		// Create a string containing the preposition we're handling
		// and the name of the state we're adding vocabulary for.
		// So if prep is 'from' and the name of the concept state is
		// 'underground golf course' then we'll get a parsed array
		// of tokens for 'from the underground golf course'.
		str = cmdTokenizer.tokenize(prep + ' ' + data.theName);

		// Now we add each of the tokens we got above as an adjective
		// in our dictionary.
		str.forEach(function(o) {
			if(o.length != 3) return;
			cmdDict.addWord(self, o[3], &adjective);
			_dynamicThingAddWeakToken(o[3]);
		});
	}

	dynamicThingEventHandler(obj?) {
		if((obj == nil) || !obj.ofKind(EventHandlerEvent))
			return;
		dynamicThingUpdateVocab(obj.data);
	}

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
