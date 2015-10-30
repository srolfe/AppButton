#import "ABWindow.h"

// StatusVol needs an auto-rotating UIWindow
@implementation ABWindow
	// Un-hide after rotation
	/*- (void)_finishedFullRotation:(id)arg1 finished:(id)arg2 context:(id)arg3{
		[super _finishedFullRotation:arg1 finished:arg2 context:arg3];
		[self setFrame:theFrame];
		
		//[self fixFrame];
		//[self setHidden:NO];
	}*/
	
	/*- (void)fixFrame{
		// Reset frame
		//long orientation=(long)[[UIDevice currentDevice] orientation];
		CGRect windowRect=self.frame;
		windowRect.origin.x=20;
		windowRect.origin.y=20;
		windowRect.size.width=60;
		windowRect.size.height=60;
		
		switch (orientation){
			case 1:{
				if (!sVolIsVisible) windowRect.origin.y=-20;
			}break;
			case 2:{
				if (!sVolIsVisible) windowRect.origin.y=20;
			}break;
			case 3:{
				if (!sVolIsVisible) windowRect.origin.x=20;
			}break;
			case 4:{
				if (!sVolIsVisible) windowRect.origin.x=-20;
			}break;
		}
		
		[self setFrame:windowRect];
	}*/
	
	// Force support auto-rotation. Hide on rotation events
	/*- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1{
		//[self setHidden:YES]; // Mitigate black box issue
		theFrame=[self frame];
		return YES;
	}*/
@end