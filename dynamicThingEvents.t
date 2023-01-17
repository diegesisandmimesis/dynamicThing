#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

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
		local st;

		st = inherited();
		if(conceptChanged(st)) {
			_conceptStateCurrent = st;
			conceptNotify();
		}
		return(st);
	}

	// Stub notification script.
	conceptNotify() {
		notifySubscribers('conceptChange');
	}
;

class DynamicThing: EventListener
	dynamicThingConcept = nil

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

	dynamicThingEventHandler(obj?) {}
;

#else // DYNAMIC_THING_EVENTS

// Define a placeholder to degrade more gracefully.
class DynamicThing: Thing;

#endif // DYNAMIC_THING_EVENTS
