#include <UIKit/UIKit.h>
#import "prefs-common.h"
#import "SAMultisectorControl.h"

@interface ABPrefsHeaderCell : PSTableCell {
	UILabel *_label;
	SAMultisectorControl *multisectorControl;
	UIImageView *theImageView;
	
	UIVisualEffectView *blurView;
	UILabel *helloLabel;
}
@end
 
@implementation ABPrefsHeaderCell
	- (id)initWithSpecifier:(PSSpecifier *)specifier{
		self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ABHeaderCell" specifier:specifier];
		
		if (self) {
			// Load prefs
			CFStringRef appID=CFSTR("com.chewmieser.appbutton");
			CFPropertyListRef angles=CFPreferencesCopyAppValue(CFSTR("MTTrayValues"),appID);
			CFPropertyListRef didExpirience=CFPreferencesCopyAppValue(CFSTR("DidExpirienceHeaderOverlay"),appID);
			
			[self setBackgroundColor:[UIColor colorWithHue:0.58 saturation:1 brightness:0.96 alpha:1]];//[UIColor colorWithHue:0.58 saturation:1 brightness:0.75 alpha:1]];
			
			CGRect theFrame=CGRectMake(50,50,150,150);
			multisectorControl=[[SAMultisectorControl alloc] initWithFrame:theFrame];
			[multisectorControl setClipsToBounds:NO];
			
			[self addSubview:multisectorControl];
			
			[multisectorControl addTarget:self action:@selector(updatePrefs) forControlEvents:UIControlEventValueChanged];
			
			// Image
			NSBundle *ourBundle=[NSBundle bundleWithPath:@"/Library/PreferenceBundles/appbuttonprefs.bundle"];
			UIImage *buttonImage=[UIImage imageWithContentsOfFile:[ourBundle pathForResource:@"appbuttonbutton" ofType:@"png"]];
			
			theImageView=[[UIImageView alloc] initWithFrame:theFrame];
			[theImageView setImage:buttonImage];
			[self addSubview:theImageView];
			//[[UIColor colorWithHue:0.49 saturation:1 brightness:0.99 alpha:1]
			//[[UIColor grayColor] colorWithAlphaComponent:0.4] //[UIColor colorWithHue:0.67 saturation:0.77 brightness:0.95 alpha:1]
			SAMultisectorSector *sector2 = [SAMultisectorSector sectorWithColor:[UIColor whiteColor] maxValue:360];

			sector2.tag = 0;

			if (angles==nil){
				sector2.startValue=90;
				sector2.endValue=270;
			}else{
				NSArray *trayValues=(__bridge NSArray *)angles;
				sector2.startValue=[((NSNumber *)[trayValues objectAtIndex:0]) integerValue];
				sector2.endValue=[((NSNumber *)[trayValues objectAtIndex:1]) integerValue];
			}
			
			[multisectorControl addSector:sector2];
			
			if (didExpirience==nil){
				// Create a quick overlay
				blurView=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
				[blurView setFrame:self.frame];
				[blurView setAlpha:0.75];
				//[blurView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
				[self addSubview:blurView];
				
				helloLabel=[[UILabel alloc] initWithFrame:self.frame];
				[helloLabel setText:@"Thank you for using AppButton"];
				[helloLabel setTextAlignment:NSTextAlignmentCenter];
				[helloLabel setTextColor:[UIColor whiteColor]];
				[helloLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:36]];
				[helloLabel setAdjustsFontSizeToFitWidth:YES];
				[blurView addSubview:helloLabel];
				[self performSelector:@selector(headerStep1) withObject:nil afterDelay:2];
			}
		}
		
		return self;
	}
	
	- (void)headerStep1{
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[helloLabel setAlpha:0];
		} completion:^(BOOL finished){
			[helloLabel setNumberOfLines:2];
			[helloLabel setText:@"To set multitasking tray angles\nuse the handles around the button"];
			
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				[helloLabel setAlpha:1];
			} completion:^(BOOL finished){
				[self performSelector:@selector(headerStep2) withObject:nil afterDelay:4];
			}];
		}];
	}
	
	- (void)headerStep2{
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[helloLabel setAlpha:0];
		} completion:^(BOOL finished){
			[helloLabel setNumberOfLines:3];
			[helloLabel setText:@"I'm always here for support!\nPlease check the about section\nfor contact information."];
			
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				[helloLabel setAlpha:1];
			} completion:^(BOOL finished){
				[self performSelector:@selector(headerStep3) withObject:nil afterDelay:4];
			}];
		}];
	}
	
	- (void)headerStep3{
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[helloLabel setAlpha:0];
		} completion:^(BOOL finished){
			[helloLabel setNumberOfLines:1];
			[helloLabel setText:@"Enjoy!"];
			
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				[helloLabel setAlpha:1];
			} completion:^(BOOL finished){
				[self performSelector:@selector(headerStep4) withObject:nil afterDelay:2];
			}];
		}];
	}
	
	- (void)headerStep4{
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[blurView setAlpha:0];
		} completion:^(BOOL finished){
			[blurView removeFromSuperview];
			
			// Save it up
			CFPreferencesSetValue(CFSTR("DidExpirienceHeaderOverlay"), (__bridge CFPropertyListRef)[NSNumber numberWithInt:1], CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
		}];
	}
	
	- (void)updatePrefs{
		SAMultisectorSector *sector=[multisectorControl.sectors objectAtIndex:0];
        int startValue=(int)sector.startValue;
        int endValue=(int)sector.endValue;
		
		NSArray *vals=[[NSArray alloc] initWithObjects:[NSNumber numberWithInt:startValue],[NSNumber numberWithInt:endValue],nil];
		
		CFPreferencesSetValue(CFSTR("MTTrayValues"), (__bridge CFPropertyListRef)vals, CFSTR("com.chewmieser.appbutton"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesAppSynchronize(CFSTR("com.chewmieser.appbutton"));
		
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chewmieser.appbutton.prefs-changed"), NULL, NULL, TRUE);
	}
 
	- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
		[blurView setFrame:CGRectMake(0,0,arg1,300)];
		
		CGRect labelFrame=blurView.frame;
		labelFrame.size.width-=150;
		labelFrame.origin.x+=75;
		[helloLabel setFrame:blurView.frame];
		
		// Return a custom cell height.
		CGRect theFrame=CGRectMake(arg1/2-125,300/2-125,250,250);
		[multisectorControl setFrame:theFrame];
		
		//CGRect theImageViewFrame=CGRectMake(arg1/2-75,300/2-75,150,150);
		CGRect theImageViewFrame=CGRectMake(arg1/2-62.5,300/2-62.5,125,125);
		[theImageView setFrame:theImageViewFrame];
		
		return 300.f;
	}
@end