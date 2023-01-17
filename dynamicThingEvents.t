#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#ifdef DYNAMIC_THING_EVENTS

modify DynamicThing
	// The current DynamicThingState
	_dtsCurrent = nil

	// Returns true if the given arg doesn't match the
	// current state.
	dtsChanged(v?) { return(v != _dtsCurrent); }

	// Modify existing DynamicThing.getDynamicThingState() to save
	// the current state and call the event hander(s) when it changes.
	getDynamicThingState() {
		local st;

		st = inherited();
		if(dtsChanged(st)) {
			_dtsCurrent = st;
			dtsNotify();
		}
		return(st);
	}

	// Stub notification script.
	dtsNotify() {
		notifySubscribers('dtsChange');
	}
;

class DynamicThingListener: EventListener
	dynamicThingSource = nil

	initializeThing() {
		inherited();
		initializeDynamicThingEventListener();
	}

	initializeDynamicThingEventListener() {
		if((dynamicThingSource == nil)
			|| !dynamicThingSource.ofKind(DynamicThing))
			return;
		dynamicThingSource.addSubscriber(self,
			&dynamicThingEventHandler, 'dtsChange');
	}

	dynamicThingEventHandler(obj?) {
		"Callback called. ";
	}
;

#endif // DYNAMIC_THING_EVENTS
