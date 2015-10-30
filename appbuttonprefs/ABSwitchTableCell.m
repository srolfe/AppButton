#import "prefs-common.h"

@interface ABSwitchTableCell : PSSwitchTableCell //our class
@end
 
@implementation ABSwitchTableCell
 
-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 { //init method
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3]; //call the super init method
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:[UIColor colorWithHue:0.58 saturation:1 brightness:0.96 alpha:1]]; //change the switch color
	}
	return self;
}
 
@end