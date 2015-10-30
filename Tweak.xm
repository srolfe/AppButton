#import "AppButton.h"
#import "ABWindow.h"
#import <notify.h>
#import <libactivator/libactivator.h>

@interface SBReachabilityManager : NSObject
+ (id)sharedInstance;
+ (_Bool)reachabilitySupported;
@property(readonly, nonatomic) _Bool reachabilityModeActive; // @synthesize reachabilityModeActive=_reachabilityModeActive;
- (void)triggerDidTriggerReachability:(id)arg1;
- (void)_keepAliveTimerFired:(id)arg1;
- (void)_clearKeepAliveTimer;
- (void)_setKeepAliveTimerForDuration:(double)arg1;
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
@end

@interface RAReachabilityManager : NSObject
+(id) sharedInstance;

-(void) launchTopAppWithIdentifier:(NSString*)identifier;
-(void) launchWidget:(id)widget;

-(void) showWidgetSelector;
@end

extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int a, int b, NSString *description);
extern "C" void BKSTerminateApplicationGroupForReasonAndReportWithDescription(int a, int b, int c, NSString *description);

static NSString * LocalizedStringForActivator(NSString *key) {
    return [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/appbuttonprefs.bundle"] localizedStringForKey:key value:key table:@"abactivator"];
}

// Handle UIControl -> tweak angle conversion
static float convertToRads(int arg1){
	// Add 180 to get base. Above 360, wrapped
	arg1+=180;
	if (arg1>360) arg1=arg1-360;
	return DEGREES_TO_RADIANS(arg1);
}

AppButton *appButtonObject;
ABWindow *abWin;
ABButtonView *abbv;
ABEventHandler *abevent;
ABEventDataSource *abeventds;

BOOL isLocked=YES;
BOOL shutUpNotificationCenter=NO;

UIVisualEffectView *blurView;

@interface UIPhysicalButtonsEvent : NSObject
-(int)type;
@end

%hook SpringBoard
	- (void)applicationDidFinishLaunching:(id)arg1{
		%orig;
		
		if (access("/var/lib/dpkg/info/com.chewmieser.appbutton.list",F_OK)!=-1){
			appButtonObject=[[AppButton alloc] init];
		}
	}
%end

@interface AXSpringBoardServer : NSObject
	+ (id)server;
	- (void)takeScreenshot;
@end
	
	/*@interface UIWindow : UIView
	- (void)drawRect:(struct CGRect)arg1;
@end*/

%hook SBScreenShotter
	- (void)saveScreenshot:(_Bool)arg1{
		[appButtonObject appButtonScreenshotHide];
		dispatch_after(0, dispatch_get_main_queue(), ^{
		    %orig;
		});
	}
%end
	
@implementation ABViewController
@end

@implementation AppButton
	- (id)init{
		self=[super init];
		if (self){
			favoriteIcons=[[NSMutableArray alloc] init];
			didTapDat=NO;
			[self loadPrefs];
			[self initializeButton];
		}
		return self;
	}
	
	- (void)hideWindow{
		[abWin setAlpha:0];
	}
	
	- (void)showWindow{
		[abWin setAlpha:1];
	}
	
	- (void)loadPrefs{
		// Setup defaults
		prefs=[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSArray arrayWithObjects:[NSNumber numberWithFloat:4.5],[NSNumber numberWithFloat:1.5],nil],@"multiTrayAngles",
			[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:40],[NSNumber numberWithFloat:40],nil],@"buttonCoordinates",
			[NSNumber numberWithInt:0],@"dockToEdge",
			[NSNumber numberWithInt:0],@"swapControls",
			[NSNumber numberWithInt:1],@"blurEnabled",
			[NSNumber numberWithInt:1],@"borderEnabled",
			[NSNumber numberWithInt:0],@"sausageFingers",
			[NSNumber numberWithInt:1],@"scrollEnabled",
			[NSNumber numberWithInt:1],@"killApps",
			[NSNumber numberWithInt:1],@"highlightApp",
			[NSNumber numberWithInt:0],@"toggleMode",
			[NSNumber numberWithInt:1],@"whitelistNowPlaying",
			[[NSArray alloc] init],@"whitelistApplications",
			@"LastApp",@"singleTap",
			@"Nothing",@"doubleTap",
			[NSNumber numberWithInt:0],@"blackButton",
			[NSNumber numberWithInt:1],@"blackTray",
			[NSNumber numberWithFloat:0.3],@"restingAlpha",
			[NSNumber numberWithFloat:1.0],@"activeAlpha",
			nil
		];
		
		// Load in prefs
		CFStringRef appID=CFSTR("com.chewmieser.appbutton");
		CFPreferencesAppSynchronize(appID);
		CFArrayRef keyList=CFPreferencesCopyKeyList(appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
		
		// Handle loaded prefs
		if (keyList!=nil){
			NSMutableDictionary *loadedPrefs=(__bridge NSMutableDictionary *)CFPreferencesCopyMultiple(keyList,appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
			
			// Handle reset case
			if ([loadedPrefs objectForKey:@"ResetSettings"]!=nil && [(NSNumber *)[loadedPrefs objectForKey:@"ResetSettings"] integerValue]){
				// Unsert reset case and ignore the remaining load
				CFPreferencesSetValue(CFSTR("ResetSettings"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset BOOLS
				CFPreferencesSetValue(CFSTR("DockToEdge"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("SwapControls"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("EnableBlur"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("EnableBorder"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("SausageFingers"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("PressHome"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("BlackButton"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("BlackTray"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("ScrollEnabled"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("KillApps"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("HighlightApp"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("ActivatorToggleMode"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("WhitelistNowPlaying"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset floats
				CFPreferencesSetValue(CFSTR("RestingAlpha"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("ActiveAlpha"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset arrays
				CFPreferencesSetValue(CFSTR("ABCoordinates"), (__bridge CFPropertyListRef)[NSArray arrayWithObjects:[NSNumber numberWithFloat:40],[NSNumber numberWithFloat:40],nil], appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("MTTrayValues"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("favoriteApplications"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("whitelistApplications"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset strings
				CFPreferencesSetValue(CFSTR("SingleTapButton"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSetValue(CFSTR("DoubleTapButton"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset expirience
				CFPreferencesSetValue(CFSTR("DidExpirienceHeaderOverlay"), NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				
				// Reset window
				if (abWin!=nil) [abWin setFrame:CGRectMake(40,40,60,60)];
				
				CFPreferencesAppSynchronize(appID);
			}else{
				// Handle BOOLs
				if ([loadedPrefs objectForKey:@"DockToEdge"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"DockToEdge"] forKey:@"dockToEdge"];
				if ([loadedPrefs objectForKey:@"SwapControls"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"SwapControls"] forKey:@"swapControls"];
				if ([loadedPrefs objectForKey:@"EnableBlur"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"EnableBlur"] forKey:@"blurEnabled"];
				if ([loadedPrefs objectForKey:@"EnableBorder"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"EnableBorder"] forKey:@"borderEnabled"];
				if ([loadedPrefs objectForKey:@"SausageFingers"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"SausageFingers"] forKey:@"sausageFingers"];
				if ([loadedPrefs objectForKey:@"PressHome"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"PressHome"] forKey:@"pressHome"];
				if ([loadedPrefs objectForKey:@"BlackButton"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"BlackButton"] forKey:@"blackButton"];
				if ([loadedPrefs objectForKey:@"BlackTray"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"BlackTray"] forKey:@"blackTray"];
				if ([loadedPrefs objectForKey:@"ScrollEnabled"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"ScrollEnabled"] forKey:@"scrollEnabled"];
				if ([loadedPrefs objectForKey:@"KillApps"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"KillApps"] forKey:@"killApps"];
				if ([loadedPrefs objectForKey:@"HighlightApp"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"HighlightApp"] forKey:@"highlightApp"];
				if ([loadedPrefs objectForKey:@"ActivatorToggleMode"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"ActivatorToggleMode"] forKey:@"toggleMode"];
				if ([loadedPrefs objectForKey:@"WhitelistNowPlaying"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"WhitelistNowPlaying"] forKey:@"whitelistNowPlaying"];
			
				// Handle floats
				if ([loadedPrefs objectForKey:@"RestingAlpha"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"RestingAlpha"] forKey:@"restingAlpha"];
				if ([loadedPrefs objectForKey:@"ActiveAlpha"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"ActiveAlpha"] forKey:@"activeAlpha"];
			
				// Handle arrays
				if ([loadedPrefs objectForKey:@"ABCoordinates"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"ABCoordinates"] forKey:@"buttonCoordinates"];
				if ([loadedPrefs objectForKey:@"MTTrayValues"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"MTTrayValues"] forKey:@"multiTrayAngles"];
				if ([loadedPrefs objectForKey:@"favoriteApplications"]!=nil) favoriteBundles=[(NSArray *)[loadedPrefs objectForKey:@"favoriteApplications"] mutableCopy];
				if ([loadedPrefs objectForKey:@"whitelistApplications"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"whitelistApplications"] forKey:@"whitelistApplications"];
				
				// Handle strings
				if ([loadedPrefs objectForKey:@"SingleTapButton"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"SingleTapButton"] forKey:@"singleTap"];
				if ([loadedPrefs objectForKey:@"DoubleTapButton"]!=nil) [prefs setObject:[loadedPrefs objectForKey:@"DoubleTapButton"] forKey:@"doubleTap"];
				
				// Adjust angles
				if ([loadedPrefs objectForKey:@"MTTrayValues"]!=nil){
					NSArray *tmp=[prefs objectForKey:@"multiTrayAngles"];
					[prefs setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:convertToRads([(NSNumber *)[tmp objectAtIndex:0] integerValue])],[NSNumber numberWithFloat:convertToRads([(NSNumber *)[tmp objectAtIndex:1] integerValue])],nil] forKey:@"multiTrayAngles"];
				}
			
				// Handle minimum allowed alpha
				if ([loadedPrefs objectForKey:@"RestingAlpha"]!=nil){
					if ([(NSNumber *)[prefs objectForKey:@"restingAlpha"] floatValue]<0.01) [prefs setObject:[NSNumber numberWithFloat:0.001960785] forKey:@"restingAlpha"];
				}
			}
			
			// Inform our view of changes
			if (abbv!=nil){
				[abbv setAlpha:[(NSNumber *)[prefs objectForKey:@"restingAlpha"] floatValue]];
				
				// Hide the border when hidden
				if ([(NSNumber *)[prefs objectForKey:@"restingAlpha"] floatValue]<=0.01){
					[abbv.layer setBorderWidth:0.0];
				}else{
					[abbv.layer setBorderWidth:1.0];
				}
				
				if (![(NSNumber *)[prefs objectForKey:@"borderEnabled"] intValue]) [abbv.layer setBorderWidth:0.0];
				
				// Handle color swapping
				if ([(NSNumber *)[prefs objectForKey:@"blackButton"] intValue]){
					[abbv setBackgroundColor:[UIColor blackColor]];
					[blurView _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
				}else{
					[abbv setBackgroundColor:[UIColor whiteColor]];
					[blurView _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
				}
				
				if ([(NSNumber *)[prefs objectForKey:@"blurEnabled"] intValue]){
					[abbv insertSubview:blurView atIndex:0];
					[abbv setBackgroundColor:[UIColor clearColor]];
					[blurView setAlpha:1.0];
				}else{
					[blurView removeFromSuperview];
					
					if ([(NSNumber *)[prefs objectForKey:@"blackButton"] intValue]){
						[abbv setBackgroundColor:[UIColor blackColor]];
					}else{
						[abbv setBackgroundColor:[UIColor whiteColor]];
					}
					
					[blurView setAlpha:0.0];
				}
			}
			
			if (![self getToggleForKey:@"toggleMode"]){
				// Peek mode
				if (abevent!=nil && [abevent hasListenerAssigned]){
					if (abWin!=nil && abWin.alpha>0){
						[self hideAppButton];
					}
				}
			}else{
				// Toggle mode
				if (abevent!=nil && [abevent hasListenerAssigned]){
					if (abWin!=nil && abWin.alpha<=0){
						[self showAppButton];
					}
				}
			}
			
			// Cache favorites
			[self cacheFavoriteIcons];
		}
	}
	
	- (void)initializeButton{
		NSArray *coordinates=(NSArray *)[self getPreferenceForKey:@"buttonCoordinates"];
		abWin=[[ABWindow alloc] initWithFrame:CGRectMake([((NSNumber *)[coordinates objectAtIndex:0]) floatValue],[((NSNumber *)[coordinates objectAtIndex:1]) floatValue],60,60)];
		abWin.windowLevel=1050;//UIWindowLevelStatusBar+1;//100;//1060;
		
		if (abevent!=nil && [abevent hasListenerAssigned]){
			[abWin setAlpha:0.0];
		}
		
		// Main view controller
		ABViewController *primaryVC=[[ABViewController alloc] init];
		
		abWin.rootViewController=primaryVC;
		[abWin makeKeyAndVisible];
		
		// Setting the frame here seems to work...
		[primaryVC.view setFrame:CGRectMake(0,0,60,60)];
		[primaryVC.view setAutoresizingMask:UIViewAutoresizingNone];
		
		// Setup "button"
		abbv=[[ABButtonView alloc] initWithFrame:CGRectMake(0,0,60,60) andButton:self];
		
		// Blur it up!
		UIBlurEffect *blurEffect;
		if ([(NSNumber *)[prefs objectForKey:@"blackButton"] intValue]){
			blurEffect=[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		}else{
			blurEffect=[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
		}
		
		blurView=[[UIVisualEffectView alloc] initWithEffect:blurEffect];
		[blurView setFrame:CGRectMake(0,0,60,60)];
		[blurView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		
		if (![self getToggleForKey:@"blurEnabled"]){
			[blurView setAlpha:0.0];
		}else{
			[abbv insertSubview:blurView atIndex:0];
		}
		
		[primaryVC.view addSubview:abbv];
	}
	
	// Cache running icons
	- (void)cacheIcons{
		bundles=[[[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary] mutableCopy];
		if (bundles==nil) bundles=[[NSMutableArray alloc] init];
		
		NSString *topBundleID=[[NSString alloc] init];
		SBApplication *sbapp=[((SpringBoard *)[UIApplication sharedApplication]) _accessibilityFrontMostApplication];
		if (sbapp!=nil){
			[bundles removeObject:[sbapp bundleIdentifier]];
			topBundleID=[sbapp bundleIdentifier];
		}	
		
		// Load icons
		theIcons=[[NSMutableArray alloc] init];
		NSMutableArray *forDeletion=[[NSMutableArray alloc] init];
		for (NSString *bundle in bundles){
			SBApplication *theApp=[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundle];
			NSArray *tags=[theApp tags];
			
			if ([theApp tags]!=nil && [tags containsObject:@"hidden"]){
				[forDeletion addObject:bundle];
			}else{
				SBApplicationIcon *theAppIcon=[[%c(SBApplicationIcon) alloc] initWithApplication:theApp];
				UIImage *theImage=[theAppIcon generateIconImage:2];
				if (theImage!=nil && ![[theApp bundleIdentifier] isEqualToString:topBundleID]){
					[theIcons addObject:theImage];
				}else{
					[forDeletion addObject:bundle];
				}
			}
		}
		
		for (NSString *bundle in forDeletion){
			[bundles removeObject:bundle];
		}
	}
	
	- (void)cacheFavoriteIcons{
		NSString *topBundleID=[[NSString alloc] init];
		SBApplication *sbapp=[((SpringBoard *)[UIApplication sharedApplication]) _accessibilityFrontMostApplication];
		if (sbapp!=nil) topBundleID=[sbapp bundleIdentifier];
		
		favoriteIcons=[[NSMutableArray alloc] init];
		if (favoriteBundles==nil) favoriteBundles=[[NSMutableArray alloc] init];
		filteredFavBundles=[favoriteBundles mutableCopy];
		[filteredFavBundles removeObject:topBundleID];
		
		favoriteIcons=[[NSMutableArray alloc] init];
		for (NSString *bundle in favoriteBundles){
			SBApplication *theApp=[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundle];
			SBApplicationIcon *theAppIcon=[[%c(SBApplicationIcon) alloc] initWithApplication:theApp];
			UIImage *theImage=[theAppIcon generateIconImage:2];
			if (theImage!=nil && ![[theApp bundleIdentifier] isEqualToString:topBundleID]){
				[favoriteIcons addObject:theImage];
			}else{
				[filteredFavBundles removeObject:bundle];
			}
		}
	}
	
	- (void)savePosition:(CGPoint)position{
		NSArray *coordinates=[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:position.x],[NSNumber numberWithFloat:position.y],nil];
		CFPreferencesSetValue(CFSTR("ABCoordinates"), (__bridge CFPropertyListRef)coordinates, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
	}
	
	- (void)didPickApplication:(NSString *)bundle{
		/*if ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ReachApp.dylib"]){
			dlopen("/Library/MobileSubstrate/DynamicLibraries/ReachApp.dylib", RTLD_NOW | RTLD_GLOBAL);
			Class ra=objc_getClass("RAReachabilityManager");
		
			if (ra!=nil){
				[[%c(SBReachabilityManager) sharedInstance] _handleReachabilityActivated];
				[[%c(RAReachabilityManager) sharedInstance] launchTopAppWithIdentifier:bundle];
			}
		}*/
		
		[[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundle]];
	}
	
	- (void)simulateHomePress{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSingleTap) object:nil];
		
		if (didTapDat){
			didTapDat=NO;
			
			BOOL didHandleEvent=NO;
		
			// Activator support
			if (abevent!=nil){
			    LAEvent *event=[LAEvent eventWithName:@"com.chewmieser.appbutton.button.double.tapped" mode:[LASharedActivator currentEventMode]];
				[LASharedActivator sendEventToListener:event];
				if (event.handled){
					didHandleEvent=YES;
				}
			}
			
			if (!didHandleEvent){
				// Handle double tap
				NSString *toDo=(NSString *)[self getPreferenceForKey:@"doubleTap"];
			
				if ([toDo isEqualToString:@"LastApp"]){
					if (bundles!=nil && [bundles count]>=1){
						[self cacheIcons];
						[self didPickApplication:[bundles objectAtIndex:0]];
					}
				}else if ([toDo isEqualToString:@"HomePress"]){
					[[%c(SBUIController) sharedInstance] clickedMenuButton];
				}else if ([toDo isEqualToString:@"DoubleHome"]){
					[[%c(SBUIController) sharedInstance] handleMenuDoubleTap];
				}
			}
		}else{
			didTapDat=YES;
			[self performSelector:@selector(doSingleTap) withObject:nil afterDelay:0.25];
		}
	}
	
	- (void)doSingleTap{
		didTapDat=NO;
		
		BOOL didHandleEvent=NO;
		
		// Activator support
		if (abevent!=nil){
		    LAEvent *event=[LAEvent eventWithName:@"com.chewmieser.appbutton.button.tapped" mode:[LASharedActivator currentEventMode]];
			[LASharedActivator sendEventToListener:event];
			if (event.handled){
				didHandleEvent=YES;
			}
		}
		
		if (!didHandleEvent){
			// Handle single tap
			NSString *toDo=(NSString *)[self getPreferenceForKey:@"singleTap"];
		
			if ([toDo isEqualToString:@"LastApp"]){
				if (bundles!=nil && [bundles count]>=1){
					[self cacheIcons];
					[self didPickApplication:[bundles objectAtIndex:0]];
				}
			}else if ([toDo isEqualToString:@"HomePress"]){
				[[%c(SBUIController) sharedInstance] clickedMenuButton];
			}else if ([toDo isEqualToString:@"DoubleHome"]){
				[[%c(SBUIController) sharedInstance] handleMenuDoubleTap];
			}
		}
	}
	
	- (void)stopNotificationCenter{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAppButton) object:nil];
		shutUpNotificationCenter=YES;
	}
	
	- (void)startNotificationCenter{
		if (![self getToggleForKey:@"toggleMode"]) [self performSelector:@selector(hideAppButton) withObject:nil afterDelay:0.5];
		shutUpNotificationCenter=NO;
	}
	
	- (void)toggleAppButton{
		if ([self getToggleForKey:@"toggleMode"]){
			if (abWin.alpha>0){
				[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
					[abWin setAlpha:0.0];
				} completion:^(BOOL finished){
				}];
			}else{
				[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
					[abWin setAlpha:1.0];
				} completion:^(BOOL finished){
				}];
			}
		}else{
			[self showAppButton];
		}
	}
	
	- (void)showAppButton{
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[abWin setAlpha:1.0];
		} completion:^(BOOL finished){
			if (![self getToggleForKey:@"toggleMode"]) [self performSelector:@selector(hideAppButton) withObject:nil afterDelay:2.0];
		}];
	}
	
	- (void)appButtonScreenshotUnhide{
		[abWin setHidden:NO];
	}
	
	- (void)appButtonScreenshotHide{
		if (abWin.hidden == NO){
			[abWin setHidden:YES];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			    [self appButtonScreenshotUnhide];
			});
		}
	}
	
	- (void)hideAppButton{
		if ((abevent!=nil && [abevent hasListenerAssigned]) || isLocked){
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				[abWin setAlpha:0.0];
			} completion:^(BOOL finished){
			}];
		}
	}
	
	- (void)updateAppButtonVisibility{
		if (!shutUpNotificationCenter){
			if (abevent!=nil && [abevent hasListenerAssigned]){
				if (abWin.alpha>0) [self hideAppButton];
			}else{
				if (abWin.alpha<1) [self showAppButton];
			}
		}
	}
	
	- (void)killAllRunningApplications{
		NSMutableArray *buns=[bundles mutableCopy];
		
		if ([self getToggleForKey:@"whitelistNowPlaying"]){
			int nppid=[((SpringBoard *)[UIApplication sharedApplication]) nowPlayingProcessPID];
			if (nppid>0){
				SBApplication *nowPlayingApp=[[%c(SBApplicationController) sharedInstance] applicationWithPid:nppid];
				[buns removeObject:[nowPlayingApp bundleIdentifier]];
			}
		}
		
		for (NSString *b in (NSArray *)[self getPreferenceForKey:@"whitelistApplications"]){
			[buns removeObject:b];
		}
		
		for (NSString *bundle in buns){
			BKSTerminateApplicationForReasonAndReportWithDescription(bundle, 1, 0, 0);
			SBAppSwitcherModel *switcherModel=[%c(SBAppSwitcherModel) sharedInstance];
			[switcherModel removeDisplayItem:[%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:bundle]];
		}
	}
	
	// Quick break-out functions
	- (id)getPreferenceForKey:(NSString *)key{ return [prefs objectForKey:key]; }
	- (BOOL)getToggleForKey:(NSString *)key{ return [(NSNumber *)[self getPreferenceForKey:key] integerValue]; }
	- (float)getFloatForKey:(NSString *)key{ return [(NSNumber *)[self getPreferenceForKey:key] floatValue]; }
	- (NSMutableArray *)icons{ return theIcons; }
	- (NSMutableArray *)identifiers{ return bundles; }
	- (UIView *)touchesView{ return [[%c(SBUIController) sharedInstance] window]; }
	- (ABWindow *)window{ return abWin; }
	- (UIVisualEffectView *)effectView{ return blurView; }
	- (NSMutableArray *)favoriteBundles{ return filteredFavBundles; }
	- (NSMutableArray *)favoriteIcons{ return favoriteIcons; }
@end

@implementation ABEventHandler
	- (id)init{
		self=[super init];
		if (self){
			[self checkVisibility];
		}
		return self;
	}
	
	- (void)checkVisibility{
		if (appButtonObject!=nil){
			[appButtonObject performSelector:@selector(updateAppButtonVisibility) withObject:nil afterDelay:0.5];
		}
	}
	
	- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event{
		if (appButtonObject!=nil){
			[appButtonObject toggleAppButton];
		}
			
		[event setHandled:YES];
	}
	
	- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event{
		if (appButtonObject!=nil){
			[appButtonObject hideAppButton];
		}
	}
	
	- (NSData *)dataForActivatorImageWithScale:(CGFloat)scale{
		NSData *data;
		if (scale<2){
			data=[NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/appbuttonprefs.bundle/appbuttonprefs.png"];
		}else if (scale==2){
			data=[NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/appbuttonprefs.bundle/appbuttonprefs@2x.png"];
		}else{
			data=[NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/appbuttonprefs.bundle/appbuttonprefs@3x.png"];
		}
		
		return data;
	}
	
	- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale{
		return [self dataForActivatorImageWithScale:*scale];
	}
	
	- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale{
		return [self dataForActivatorImageWithScale:*scale];
	}
	
	- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale{
		return [UIImage imageWithData:[self dataForActivatorImageWithScale:scale]];
	}
	
	- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale{
		return [UIImage imageWithData:[self dataForActivatorImageWithScale:scale]];
	}
		
	- (BOOL)hasListenerAssigned{
		NSArray *tmp=[LASharedActivator eventsAssignedToListenerWithName:@"com.chewmieser.appbutton"];
		return tmp!=nil && [tmp count]>0;
	}
	
	- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
		return @"AppButton";
	}
	
	- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
		return LocalizedStringForActivator(@"ACTIVATE_APPBUTTON_LISTENER_TITLE");
	}
	
	- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
		return LocalizedStringForActivator(@"ACTIVATE_APPBUTTON_LISTENER_DESCRIPTION");
	}
	
	- (void)activator:(LAActivator *)activator receivePreviewEventForListenerName:(NSString *)listenerName{
		if (appButtonObject!=nil){
			[appButtonObject performSelector:@selector(updateAppButtonVisibility) withObject:nil afterDelay:0.5];
		}
	}
@end
	
@implementation ABEventDataSource
	- (NSString *)localizedTitleForEventName:(NSString *)eventName{
		NSString *title;
		if ([eventName isEqualToString:@"com.chewmieser.appbutton.button.tapped"]){
			title=LocalizedStringForActivator(@"EVENT_TAP_BUTTON_ONCE_TITLE");
		}else{
			title=LocalizedStringForActivator(@"EVENT_TAP_BUTTON_TWICE_TITLE");
		}
		
		return title;
	}
 
	- (NSString *)localizedGroupForEventName:(NSString *)eventName{
	        return @"AppButton";
	}
 
	- (NSString *)localizedDescriptionForEventName:(NSString *)eventName{
		NSString *title;
		if ([eventName isEqualToString:@"com.chewmieser.appbutton.button.tapped"]){
			title=LocalizedStringForActivator(@"EVENT_TAP_BUTTON_ONCE_DESCRIPTION");
		}else{
			title=LocalizedStringForActivator(@"EVENT_TAP_BUTTON_TWICE_DESCRIPTION");
		}
		
		return title;
	}
@end

// Reload preferences when changed
static void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	if (appButtonObject!=nil) [appButtonObject loadPrefs];
}

static void ActivatorAssignmentChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	if (abevent!=nil) [abevent checkVisibility];
}

static void DidLockDevice(){
	isLocked=YES;
	if (appButtonObject!=nil) [appButtonObject hideAppButton];
}

static void DidUnlockDevice(){
	isLocked=NO;
	if (appButtonObject!=nil) [appButtonObject showAppButton];
}

%ctor{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Register for unlock/lock events
		int notify_token;
		notify_register_dispatch("com.apple.springboard.lockstate",&notify_token,dispatch_get_main_queue(),^(int token){
			uint64_t state = UINT64_MAX;
			notify_get_state(token, &state);
			if(state==0){
		        DidUnlockDevice();
			}else{
		        DidLockDevice();
			}
		});
	
		// Register for preference notifications
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChanged, CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		
		// Look for Activator
		dlopen("/usr/lib/libactivator.dylib",RTLD_LAZY);
		Class la=objc_getClass("LAActivator");
	
		// If found, setup event handler, register listener and watch for libactivator notifications
		if (la!=nil){
			abevent=[[ABEventHandler alloc] init];
			abeventds=[[ABEventDataSource alloc] init];
		
			[LASharedActivator registerEventDataSource:abeventds forEventName:@"com.chewmieser.appbutton.button.tapped"];
			[LASharedActivator registerEventDataSource:abeventds forEventName:@"com.chewmieser.appbutton.button.double.tapped"];
		
			if ([LASharedActivator isRunningInsideSpringBoard]) {
				[LASharedActivator registerListener:abevent forName:@"com.chewmieser.appbutton"];
			}
		
			// Handle unassigned case
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ActivatorAssignmentChanged, CFSTR("libactivator.assignments.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		}
	});
}