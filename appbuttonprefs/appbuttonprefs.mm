#import "prefs-common.h"

@interface appbuttonprefsListController: PSListController {
}
@end

@implementation appbuttonprefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"appbuttonprefs" target:self];
	}
	return _specifiers;
}
@end

// vim:ft=objc
