#import "prefs-common.h"

@interface ABAboutController: PSListController {
}
@end

@implementation ABAboutController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"ababout" target:self];
	}
	return _specifiers;
}

- (void)openTwitter:(id)sender{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/chewmieser"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=chewmieser"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=chewmieser"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=chewmieser"]];
	}else{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/chewmieser"]];
	}
}

- (void)openKylesTwitter:(id)sender{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/krevony"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=krevony"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=krevony"]];
	}else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=krevony"]];
	}else{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/krevony"]];
	}
}

- (NSString *)languageForSpecifier:(PSSpecifier *)specifier{
	return [specifier propertyForKey:@"language"];
}

- (void)emailMe:(id)sender{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:steve@rolfe.land?subject=AppButton%200.8.3&body=I%20love%20AppButton!"]];
}

- (void)resetSettings:(id)sender{
	CFPreferencesSetValue(CFSTR("ResetSettings"), (__bridge CFPropertyListRef)[NSNumber numberWithInt:1], CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section<2){
		return 70;
	}else{
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	}
}

@end

// vim:ft=objc