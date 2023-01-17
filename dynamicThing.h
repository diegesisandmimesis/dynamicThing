//
// dynamicThing.h
//

//
// BEGIN EDITABLE OPTIONS
//
// The #define statements in this block of comments can be enabled or
// disabled to suit your needs.
//
// Uncomment to enable notifications.
// Only needed if you want objects to be able to update their vocabularies
// to reflect dynamic word changes.
//#define DYNAMIC_THING_EVENTS
//
// Uncomment to enable debugging options.
//#define __DEBUG_DYNAMIC_THING
//
// END EDITABLE OPTIONS
//

//
// NO EDITABLE OPTIONS BELOW THIS POINT
//
// If the above in uncommented, then we need to include the eventHandler
// module to support the features.
#ifdef DYNAMIC_THING_EVENTS
#include "eventHandler.h"
#ifndef EVENT_HANDLER_VERSION
#error "This module requires the eventHandler module."
#error "https://github.com/diegesisandmimesis/eventHandler"
#error "It should be in the same parent directory as this module.  So if"
#error "dynamicThing is in /home/user/tads/dynamicThing, then eventHandler"
#error "should be in /home/user/tads/eventHandler ."
#endif // EVENT_HANDLER_VERSION
#endif // DYNAMIC_THING_EVENTS

DynamicThing template 'dynamicThingID';
DynamicThingState template 'vocabWords' 'name' +dtsOrder? 'dtsRevealKey'?;
