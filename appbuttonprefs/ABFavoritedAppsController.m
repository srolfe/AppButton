#import "prefs-common.h"
#import <AppList/AppList.h>

extern NSString *PSDeletionActionKey;

@interface PSEditableListController : PSListController
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
- (void)setEditingButtonHidden:(BOOL)arg1 animated:(BOOL)arg2;
@end

@interface ABFavoritedAppsController : PSEditableListController {
	ALApplicationList *apps;
	NSArray *displayIdentifiers;
	NSMutableArray *favorites;
}
@end

@implementation ABFavoritedAppsController
	- (NSString *)localizedString:(NSString *)key{
	    return [[NSBundle bundleForClass: [self class]] localizedStringForKey:key value:key table:@"abfavorites"];
	}

	- (id)specifiers {
		if(_specifiers==nil) {
			CFStringRef appID=CFSTR("com.chewmieser.appbutton");
			CFPropertyListRef favs=CFPreferencesCopyAppValue(CFSTR("favoriteApplications"),appID);
			if (favs!=nil){
				favorites=[(__bridge NSArray *)favs mutableCopy];
			}else{
				favorites=[[NSMutableArray alloc] init];
			}
			
			if (apps==nil){
				apps=[ALApplicationList sharedApplicationList];
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					if (displayIdentifiers==nil) displayIdentifiers = [[[apps applications] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
						return [[[apps applications] objectForKey:obj1] caseInsensitiveCompare:[[apps applications] objectForKey:obj2]];}];

				    // If you then need to execute something making sure it's on the main thread (updating the UI for example)
				    dispatch_async(dispatch_get_main_queue(), ^{
				        [self reloadSpecifiers];
				    });
				});
			}
		}
		
		NSMutableArray *specs=[[NSMutableArray alloc] init];
			
		PSSpecifier *favGroup=[PSSpecifier groupSpecifierWithName:[self localizedString:@"FAVORITES_HEADER"]];
		[specs addObject:favGroup];
		
		for (NSString *displayId in favorites){
			PSSpecifier *s=[PSSpecifier preferenceSpecifierNamed:[apps.applications objectForKey:displayId] target:nil set:nil get:nil detail:nil cell:PSListItemCell edit:nil];
			[s setProperty:displayId forKey:@"displayIdentifier"];
			//[s setProperty:NSStringFromSelector(@selector(removeFavorite:)) forKey:@"deletionAction"];
			[specs addObject:s];
		}
			
		// Create applist group
		PSSpecifier *appGroup=[PSSpecifier groupSpecifierWithName:[self localizedString:@"ALL_APPS_HEADER"]];
		[specs addObject:appGroup];
		
		for (NSString *displayId in displayIdentifiers){
			if (![favorites containsObject:displayId]){
				PSSpecifier *s=[PSSpecifier preferenceSpecifierNamed:[apps.applications objectForKey:displayId] target:nil set:nil get:nil detail:nil cell:PSListItemCell edit:nil];
				[s setProperty:displayId forKey:@"displayIdentifier"];
				[specs addObject:s];
			}
		}
		
		if (displayIdentifiers==nil){
			PSSpecifier *s=[PSSpecifier preferenceSpecifierNamed:[self localizedString:@"LOADING_TEXT"] target:nil set:nil get:nil detail:nil cell:PSListItemCell edit:nil];
			[specs addObject:s];
		}
		
		_specifiers=[specs copy];
		
		[[self table] setEditing:YES];
		[[self table] setAllowsSelectionDuringEditing:YES];
		[self setEditingButtonHidden:YES animated:NO];
			
		return _specifiers;
	}
	
	// Lock moving inside section only
	- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
		if (sourceIndexPath.section != proposedDestinationIndexPath.section){
			NSInteger row=0;
			if (sourceIndexPath.section < proposedDestinationIndexPath.section){
				row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
			}
			return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];     
		}
		
		return proposedDestinationIndexPath;
	}
	
	- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
		id object=[favorites objectAtIndex:fromIndexPath.row];
		[favorites removeObjectAtIndex:fromIndexPath.row];
		[favorites insertObject:object atIndex:toIndexPath.row];
		
		CFPreferencesSetValue(CFSTR("favoriteApplications"), (__bridge CFPropertyListRef)favorites, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
	
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
	}
	
	- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
		return indexPath.section==0;
	}
	
	- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
		return indexPath.section==0;
	}
	
	- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
		[super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
		
		if (editingStyle==UITableViewCellEditingStyleDelete){
			[favorites removeObjectAtIndex:indexPath.row];
			CFPreferencesSetValue(CFSTR("favoriteApplications"), (__bridge CFPropertyListRef)favorites, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
	
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
			
			[self reloadSpecifiers];
		}
	}
	
	- (void)tableView:(UITableView *)arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2{
		[arg1 deselectRowAtIndexPath:arg2 animated:YES];
		/*
		- (void)insertSpecifier:(id)arg1 atEndOfGroup:(int)arg2;
		- (void)removeSpecifierAtIndex:(int)arg1;
		- (void)_moveSpecifierAtIndex:(unsigned int)arg1 toIndex:(unsigned int)arg2 animated:(BOOL)arg3;
		- (NSArray *)specifiersInGroup:(int)arg1;
		- (int)indexOfGroup:(int)arg1;
		- (void)insertSpecifier:(id)arg1 atEndOfGroup:(int)arg2;
		*/
		/*if (arg2.section==1){
			PSSpecifier *spec=[self specifierAtIndex:[self indexForIndexPath:arg2]];
			[favorites addObject:[spec propertyForKey:@"displayIdentifier"]];
			[self insertSpecifier:nil atEndOfGroup:0];
			[self _moveSpecifierAtIndex:[self indexForIndexPath:arg2] toIndex:[self indexOfGroup:1]-1 animated:YES];
			
			CFPreferencesSetValue(CFSTR("favoriteApplications"), (__bridge CFPropertyListRef)favorites, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
		
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
		}*/
		
		if (arg2.section==1){
			PSSpecifier *spec=[self specifierAtIndex:[self indexForIndexPath:arg2]];
			
			if ([spec propertyForKey:@"displayIdentifier"]!=nil){
				[favorites addObject:[spec propertyForKey:@"displayIdentifier"]];
			
				CFPreferencesSetValue(CFSTR("favoriteApplications"), (__bridge CFPropertyListRef)favorites, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
		
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
		
				[self reloadSpecifiers];
			}
		}
	}
	
	- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
		
		PSSpecifier *spec=[self specifierAtIndex:[self indexForIndexPath:indexPath]];
		
		if ([spec propertyForKey:@"displayIdentifier"]!=nil){
			UIImage *icon=[apps iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:[spec propertyForKey:@"displayIdentifier"]];
			[cell setIcon:icon];
		}
		
		return cell;
	}
@end