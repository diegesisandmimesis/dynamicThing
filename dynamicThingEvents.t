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
	dynamicThingConcept = nil

	initializeThing() {
		inherited();
		initializeDynamicThingEventListener();
		//saveDynamicThingInitState();
	}

	initializeDynamicThingEventListener() {
		if((dynamicThingConcept == nil)
			|| !dynamicThingConcept.ofKind(Concept))
			return;
		dynamicThingConcept.addSubscriber(self,
			&dynamicThingEventHandler, 'conceptChange');
	}

	dynamicThingUpdateVocab(data) {
		// Make sure the argument we got it valid.
		if((data == nil) || !data.ofKind(ConceptState))
			return(nil);

		// Just reset our vocabulary.
		initializeVocab();
		local str = cmdTokenizer.tokenize('to the '
			+ data.theName);

		str.forEach(function(o) {
			if(o.length != 3) return;
			cmdDict.addWord(self, o[3], &adjective);
		});
		cmdDict.addWord(self, data.adjective, &adjective);
		cmdDict.addWord(self, data.noun, &adjective);
		cmdDict.addWord(self, noun, &adjective);

		return(true);
	}

	dynamicThingEventHandler(obj?) {
		if((obj == nil) || !obj.ofKind(EventHandlerEvent))
			return;
		dynamicThingUpdateVocab(obj.data);
	}
;

#else // DYNAMIC_THING_EVENTS

// Define a placeholder to degrade more gracefully.
class DynamicThing: Thing;

#endif // DYNAMIC_THING_EVENTS
