#import "prefs-common.h"
#import <objc/runtime.h>
#include <dlfcn.h>

@interface ABSwitchTableCell : PSSwitchTableCell //our class
@end

@interface ABBehaviorController: PSListController {
}
@end

@implementation ABBehaviorController
- (NSString *)localizedString:(NSString *)key{
    return [[NSBundle bundleForClass: [self class]] localizedStringForKey:key value:key table:@"abbehavior"];
}

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *specs=[self loadSpecifiersFromPlistName:@"abbehavior" target:self];
		
		// Look for Activator
		dlopen("/usr/lib/libactivator.dylib",RTLD_LAZY);
		Class la=objc_getClass("LAActivator");
		
		if (la!=nil){
			// Inject Activator group
			PSSpecifier *activatorGroup=[PSSpecifier emptyGroupSpecifier];
			[activatorGroup setProperty:[self localizedString:@"APPBUTTON_ACTIVATOR_ACTIVATION_FOOTER"] forKey:@"footerText"];
			[specs insertObject:activatorGroup atIndex:2];
			
			// Inject activator specifier
			PSSpecifier *activatorSpecifier=[PSSpecifier preferenceSpecifierNamed:[self localizedString:@"APPBUTTON_ACTIVATOR_ACTIVATION_METHODS_LABEL"] target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
			[activatorSpecifier setProperty:@"com.chewmieser.appbutton" forKey:@"activatorListener"];
			[activatorSpecifier setProperty:[NSBundle bundleWithIdentifier:@"com.libactivator.preferencebundle"].bundlePath forKey:@"lazy-bundle"];
			[activatorSpecifier setProperty:[self localizedString:@"APPBUTTON_ACTIVATOR_ACTIVATION_METHODS_HEADER"] forKey:@"activatorTitle"];
			activatorSpecifier->action=@selector(lazyLoadBundle:);
			
			[specs insertObject:activatorSpecifier atIndex:3];
			
			// Inject activator toggle
			PSSpecifier *activatorToggleSpec=[PSSpecifier preferenceSpecifierNamed:[self localizedString:@"APPBUTTON_ACTIVATOR_ACTIVATION_TOGGLE_MODE_LABEL"] target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
			[activatorToggleSpec setProperty:[ABSwitchTableCell class] forKey:@"cellClass"];
			[activatorToggleSpec setProperty:@YES forKey:@"enabled"];
			[activatorToggleSpec setProperty:@NO forKey:@"default"];
			[activatorToggleSpec setProperty:@"com.chewmieser.appbutton" forKey:@"defaults"];
			[activatorToggleSpec setProperty:@"com.chewmieser.appbutton.prefs-changed" forKey:@"PostNotification"];
			[activatorToggleSpec setProperty:@"ActivatorToggleMode" forKey:@"key"];
			
			[specs insertObject:activatorToggleSpec atIndex:4];
			
			// Manipulate single tap event group
			PSSpecifier *singleTapGroupSpecifier=(PSSpecifier *)[specs objectAtIndex:5];
			[singleTapGroupSpecifier setProperty:[self localizedString:@"SINGLE_TAP_ACTION_FOOTER_WITH_ACTIVATOR"] forKey:@"footerText"];
			[specs replaceObjectAtIndex:5 withObject:singleTapGroupSpecifier];
			
			// Manipulate double tap event group
			PSSpecifier *doubleTapGroupSpecifier=(PSSpecifier *)[specs objectAtIndex:7];
			[doubleTapGroupSpecifier setProperty:[self localizedString:@"DOUBLE_TAP_ACTION_FOOTER_WITH_ACTIVATOR"] forKey:@"footerText"];
			[specs replaceObjectAtIndex:7 withObject:doubleTapGroupSpecifier];
			
			// Inject single-tap activator event
			PSSpecifier *activatorABSingleTap=[PSSpecifier preferenceSpecifierNamed:[self localizedString:@"TAP_ACTION_ACTIVATOR_OTHER"]  target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
			[activatorABSingleTap setProperty:@"com.chewmieser.appbutton.button.tapped" forKey:@"activatorEvent"];
			[activatorABSingleTap setProperty:[NSBundle bundleWithIdentifier:@"com.libactivator.preferencebundle"].bundlePath forKey:@"lazy-bundle"];
			[activatorABSingleTap setProperty:[self localizedString:@"SINGLE_TAP_ACTIVATOR_HEADER"] forKey:@"activatorTitle"];
			activatorABSingleTap->action=@selector(lazyLoadBundle:);
			
			[specs insertObject:activatorABSingleTap atIndex:7];
			
			// Inject double-tap activator event
			PSSpecifier *activatorABDoubleTap=[PSSpecifier preferenceSpecifierNamed:[self localizedString:@"TAP_ACTION_ACTIVATOR_OTHER"] target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
			[activatorABDoubleTap setProperty:@"com.chewmieser.appbutton.button.double.tapped" forKey:@"activatorEvent"];
			[activatorABDoubleTap setProperty:[NSBundle bundleWithIdentifier:@"com.libactivator.preferencebundle"].bundlePath forKey:@"lazy-bundle"];
			[activatorABDoubleTap setProperty:[self localizedString:@"DOUBLE_TAP_ACTIVATOR_HEADER"] forKey:@"activatorTitle"];
			activatorABDoubleTap->action=@selector(lazyLoadBundle:);
			
			[specs insertObject:activatorABDoubleTap atIndex:10];
		}
		
		_specifiers=[specs copy];
	}
	return _specifiers;
}
@end

// vim:ft=objc
