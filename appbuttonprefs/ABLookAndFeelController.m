#import "prefs-common.h"

@interface ABLookAndFeelController: PSListController {
}
@end

@implementation ABLookAndFeelController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"abaesthetics" target:self];
	}
	return _specifiers;
}
@end

// vim:ft=objc
