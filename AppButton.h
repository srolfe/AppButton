#import "common.h"
#import "ABWindow.h"
#import <libactivator/libactivator.h>

#pragma clang diagnostic ignored "-Wswitch"
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface ABEventDataSource: NSObject <LAEventDataSource>
@end

@interface ABEventHandler : NSObject <LAListener>{
	NSTimer *visibilityTimer;
}
	- (BOOL)hasListenerAssigned;
	- (void)checkVisibility;
	- (NSData *)dataForActivatorImageWithScale:(CGFloat)scale;
@end

@interface ABViewController : UIViewController
@end

@interface AppButton : NSObject{
	NSMutableArray *theIcons;
	NSMutableArray *bundles;
	
	NSMutableArray *favoriteBundles;
	NSMutableArray *favoriteIcons;
	NSMutableArray *filteredFavBundles;
	
	BOOL didTapDat;
	
	NSMutableDictionary *prefs;
}
	- (id)init;
	- (void)initializeButton;
	- (void)cacheIcons;
	- (NSMutableArray *)icons;
	- (NSMutableArray *)identifiers;
	- (NSMutableArray *)favoriteBundles;
	- (NSMutableArray *)favoriteIcons;
	- (void)cacheFavoriteIcons;
	- (void)savePosition:(CGPoint)position;
	
	- (id)getPreferenceForKey:(NSString *)key;
	- (BOOL)getToggleForKey:(NSString *)key;
	- (float)getFloatForKey:(NSString *)key;
	
	- (UIView *)touchesView;
	- (UIVisualEffectView *)effectView;
	- (ABWindow *)window;
	
	- (void)didPickApplication:(NSString *)bundle;
	- (void)simulateHomePress;
	
	- (void)stopNotificationCenter;
	- (void)startNotificationCenter;
	
	- (void)hideWindow;
	- (void)showWindow;
	- (void)appButtonScreenshotHide;
	- (void)appButtonScreenshotUnhide;
	
	- (void)toggleAppButton;
	- (void)showAppButton;
	- (void)hideAppButton;
	- (void)updateAppButtonVisibility;
	
	- (void)killAllRunningApplications;
@end
	
	
@interface ABButtonView : UIView{
	BOOL isMovable;
	BOOL isPositionable;
	BOOL didSomething;
	float maxTrayHeight;
	UIImageView *iconImageView;
	AppButton *abutton;
	ABWindow *abWin;
	
	CGPoint firstTouch;
	
	float lastAngle;
	int currentView;
	
	NSMutableArray *filteredFavBundles;
	NSMutableArray *favoriteIcons;
	
	NSMutableDictionary *cachedColors;
	
	UIScrollView *trayView;
	
	BOOL isExpanding;
	BOOL isShrinking;
	
	float capHeight;
	float heightForScroll;
	
	BOOL clearTrayWaiting;
	BOOL willDestroyMultitasking;
}
	- (id)initWithFrame:(CGRect)frame andButton:(AppButton *)button;
	- (void)unlockOpenTray;
	- (void)lockOpenTray;
	- (void)configureLayout;
	- (void)setupIconView;
	
	- (void)scrollToEnd;
	- (void)scrollToBeginning;
	- (void)stopScrolling;
	
	- (int)calculateIconNumber;
	
	- (void)clearMultitaskingTrigger;
@end