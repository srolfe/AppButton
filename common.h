@interface UIImage (ColorAtPixel)
	- (UIColor *)colorAtPixel:(CGPoint)point;
@end

@interface UIVisualEffectView (ex)
	- (void)_setEffect:(id)arg1;
@end

@interface UIWindow (ex)
	- (void)_setSecure:(BOOL)arg1;
	- (void)_finishedFullRotation:(id)arg1 finished:(id)arg2 context:(id)arg3;
	- (void)_updateToInterfaceOrientation:(int)arg1 animated:(BOOL)arg2;
	- (void)setHidden:(BOOL)arg1;
	- (void)_resignKeyWindowStatus;
	- (void)_orderFrontWithoutMakingKey;
	- (void)setBecomeKeyOnOrderFront:(BOOL)arg1;
	- (void)setAutorotates:(BOOL)arg1 forceUpdateInterfaceOrientation:(BOOL)arg2;
	- (void)setAutorotates:(BOOL)arg1;
	- (void)makeKey:(id)arg1;
@end

@interface SBIcon
	- (id)applicationBundleID;
@end

@interface SBIconView : UIView
	@property(retain, nonatomic) SBIcon *icon;
	- (void)setHighlighted:(_Bool)arg1;
@end

@interface SBIconController
	- (void)clearHighlightedIcon;
@end

@interface SBApplicationIcon
	- (UIImage *)generateIconImage:(int)arg1;
	- (id)getUnmaskedIconImage:(int)arg1;
	- (id)initWithApplication:(id)arg1;
@end
	
@interface SBAppSwitcherModel
	- (void)removeDisplayItem:(id)arg1;
	- (void)remove:(id)arg1;
	+ (id)sharedInstance;
	- (NSArray *)snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary;
@end

@interface SBApplication
	- (id)mainSceneID;
	- (id)mainScene;
	- (id)bundleIdentifier;
	- (id)_screenFromSceneID:(id)arg1;
	- (_Bool)isInternalApplication;
	- (_Bool)isSystemApplication;
	- (NSArray *)tags;
@end

@interface SBApplicationController
	+ (id)sharedInstance;
	- (id)applicationWithPid:(int)arg1;
	- (SBApplication *)applicationWithBundleIdentifier:(id)arg1;
@end

@interface SBDisplayItem : NSObject
	+ (id)displayItemWithType:(NSString *)arg1 displayIdentifier:(id)arg2;
	@property(readonly, nonatomic) NSString *displayIdentifier;
@end

@interface SBDisplayLayout : NSObject
	@property(readonly, nonatomic) NSArray *displayItems;
@end

@interface SBAppSwitcherIconController : UIViewController{
	NSMutableArray *_appList;
    NSMutableDictionary *_iconViews;
}
@end

@interface SBAppSwitcherServices
@property(readonly, nonatomic) NSMutableArray *services; // @synthesize services=_services;
- (id)displayItems;
- (id)serviceBundleIdentifiers;
- (id)serviceForIdentifier:(id)arg1;
- (id)serviceForBundleIdentifier:(id)arg1;
- (id)serviceAtIndex:(unsigned long long)arg1;
- (unsigned long long)count;
- (void)removeService:(id)arg1;
- (void)addService:(id)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (void)dealloc;
- (id)initWithServices:(id)arg1 zone:(struct _NSZone *)arg2;
@end

@interface SBAppSwitcherController : UIViewController{
	NSMutableArray *_appList_use_block_accessor;
	NSMutableSet *_hostedApplications;
	SBAppSwitcherServices *_switcherServices_use_block_accessor;
}

	- (void)_rebuildAppListCache;
	- (void)_destroyAppListCache;
	@property(readonly, nonatomic) SBAppSwitcherIconController *iconController;

@end

@interface SBUIController
	+(id)sharedInstance;
	-(void)clickedMenuButton;
	-(void)handleMenuDoubleTap;
	-(void)activateApplicationAnimated:(id)arg1;
	-(SBAppSwitcherController *)switcherController;
@end

@interface SpringBoard : UIApplication{
}
	@property(nonatomic) int nowPlayingProcessPID;
	- (id)_accessibilityRunningApplications;
	- (id)_accessibilityFrontMostApplication;
	- (id)_keyWindowForScreen:(id)arg1;
@end