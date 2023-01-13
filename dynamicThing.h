//
// dynamicThing.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_DYNAMIC_THING

/*
DynamicThing template 'dynamicThingID' 'dynamicThingDefault'? [dynamicThingStateTable]?;

#define DefineDynamicThing(base, id, def, table...) \
	base##DynamicThing: DynamicThing \
		dynamicThingState = new DynamicThingState(id, def, table)
*/
DynamicThing template 'dynamicThingID';
DynamicThingState template 'vocabWords' 'name' 'revealFlag'?;
