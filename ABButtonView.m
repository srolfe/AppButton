#import "AppButton.h"

@implementation ABButtonView
	- (id)initWithFrame:(CGRect)frame andButton:(AppButton *)button{
		self=[super initWithFrame:frame];
		if (self){
			cachedColors=[[NSMutableDictionary alloc] init];
			filteredFavBundles=[button favoriteBundles];
			favoriteIcons=[button favoriteIcons];
			
			lastAngle=1.57079633;
			abWin=[button window];
			abutton=button;
			[self configureLayout];
			[self setupIconView];
		}
		return self;
	}
	
	// Sets up the initial button look
	- (void)configureLayout{
		trayView=[[UIScrollView alloc] initWithFrame:CGRectMake(0,60,0,0)];
		[trayView setUserInteractionEnabled:NO];
		[self insertSubview:trayView atIndex:1];
		
		// Cap tray height
		maxTrayHeight=0.0;
		
		if (![abutton getToggleForKey:@"blurEnabled"]){
			if ([abutton getToggleForKey:@"blackButton"]){
				[self setBackgroundColor:[UIColor blackColor]];
			}else{
				[self setBackgroundColor:[UIColor whiteColor]];
			}
		}
		
		[self.layer setCornerRadius:30];
		[self.layer setBorderColor:[UIColor blackColor].CGColor];
		
		// Set style
		[self setAlpha:[abutton getFloatForKey:@"restingAlpha"]];
		if ([abutton getFloatForKey:@"restingAlpha"]<=0.01){
			[self.layer setBorderWidth:0.0];
		}else{
			[self.layer setBorderWidth:1.0];
		}
		
		if (![abutton getToggleForKey:@"borderEnabled"]) [self.layer setBorderWidth:0.0];
		
		[self setClipsToBounds:YES];
	}
	
	// Sets up the imageview
	- (void)setupIconView{
		iconImageView=[[UIImageView alloc] initWithFrame:CGRectMake(self.frame.origin.x+5,self.frame.origin.y+5,self.frame.size.width-10,self.frame.size.height-10)];
		[iconImageView setContentMode:UIViewContentModeScaleToFill];
		[iconImageView setClipsToBounds:YES];
		[iconImageView.layer setCornerRadius:iconImageView.bounds.size.width/2];
		[iconImageView.layer setMasksToBounds:YES];
		[iconImageView.layer setBorderWidth:0.0];
		[iconImageView.layer setBorderColor:[UIColor whiteColor].CGColor];
		[iconImageView setTag:1337];
		
		[self addSubview:iconImageView];
	}
	
	// Handle touch began
	- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
		willDestroyMultitasking=false;
		clearTrayWaiting=false;
		
		heightForScroll=0;
		[abutton stopNotificationCenter];
		
		UITouch *touch=[[event allTouches] anyObject];
		firstTouch=[touch locationInView:[abutton touchesView]];
		didSomething=NO;
		
		[self setAlpha:[abutton getFloatForKey:@"activeAlpha"]];
		[abutton cacheIcons];
		[abutton cacheFavoriteIcons];
		
		if ([abutton getFloatForKey:@"restingAlpha"]<0.1 && [abutton getToggleForKey:@"borderEnabled"]){
			[self.layer setBorderWidth:1.0];
		}
		
		if ([abutton getToggleForKey:@"swapControls"]){
			[self unlockMove];
			[self performSelector:@selector(unlockOpenTray) withObject:nil afterDelay:0.5];
		}else{
			[self unlockOpenTray];
			[self performSelector:@selector(unlockMove) withObject:nil afterDelay:0.5];
		}
	}
	
	- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
		didSomething=YES;
		
		UITouch *touch=[[event allTouches] anyObject];
		CGPoint touchLocation=[touch locationInView:[abutton touchesView]];
		
		if (touchLocation.x>firstTouch.x+10 || touchLocation.x<firstTouch.x-10 || touchLocation.y>firstTouch.y+10 || touchLocation.y<firstTouch.y-10){
			if ([abutton getToggleForKey:@"swapControls"]){
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unlockMove) object:nil];
			}else{
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unlockMove) object:nil];
			}
		}
		
		if (!isPositionable){
			// Reset transformation
			self.superview.transform=CGAffineTransformIdentity;
			
			// Find origin -> touch distance
			int originToTouchY=floor(touchLocation.y-abWin.frame.origin.y);
			int originToTouchX=floor(touchLocation.x-abWin.frame.origin.x);
			
			// Calculate new height (pythagorean)
			float newHeight=sqrt(pow(originToTouchX,2)+pow(originToTouchY,2));
			
			// Cap newHeight
			if (newHeight<60) newHeight=60;
			if (newHeight>maxTrayHeight) newHeight=maxTrayHeight;
			
			// Calculate angle from 90deg
			float initialAngle=1.57079633;
			float newAngle=atan2(originToTouchY,originToTouchX);
			if (newAngle<initialAngle) newAngle+=2*M_PI;
			float angle=newAngle-initialAngle;
			
			// Load tray angles
			NSArray *angles=(NSArray *)[abutton getPreferenceForKey:@"multiTrayAngles"];
			float startValue=[((NSNumber *) [angles objectAtIndex:0]) floatValue];
			float endValue=[((NSNumber *) [angles objectAtIndex:1]) floatValue];
			
			// Adjust for orientation
			UIInterfaceOrientation interfaceOrientation=[UIApplication sharedApplication].statusBarOrientation;
			switch (interfaceOrientation){
				case UIInterfaceOrientationPortraitUpsideDown:{
					startValue+=DEGREES_TO_RADIANS(180);
					endValue+=DEGREES_TO_RADIANS(180);
				}break;
				case UIInterfaceOrientationLandscapeLeft:{
					startValue+=DEGREES_TO_RADIANS(270);
					endValue+=DEGREES_TO_RADIANS(270);
				}break;
				case UIInterfaceOrientationLandscapeRight:{
					startValue+=DEGREES_TO_RADIANS(90);
					endValue+=DEGREES_TO_RADIANS(90);
				}break;
				default:;break;
			}
			
			if (startValue>DEGREES_TO_RADIANS(360)) startValue-=DEGREES_TO_RADIANS(360);
			if (endValue>DEGREES_TO_RADIANS(360)) endValue-=DEGREES_TO_RADIANS(360);
			
			BOOL didRelayout=NO;
			
			// Reload trays if needed
			if ((startValue<endValue && (angle>startValue && angle<endValue)) || (startValue>endValue && (angle>startValue || angle<endValue))){
				if ((lastAngle<startValue || lastAngle>endValue) && currentView==1){
					didRelayout=YES;
					[self clearTray];
					[self layoutIcons:0];
					currentView=0;
				}
			}else{
				if (lastAngle>startValue || lastAngle<endValue || currentView==0){
					didRelayout=YES;
					[self clearTray];
					[self layoutIcons:1];
					currentView=1;
				}
			}
			
			// Store last angle
			lastAngle=angle;
			
			// Set angle transform on super
			CGAffineTransform transform=CGAffineTransformRotate(CGAffineTransformIdentity,angle);
			self.superview.transform=transform;
			
			// Reverse transform and set on UIImageViews
			CGAffineTransform rTrans=CGAffineTransformInvert(transform);
			CGAffineTransform iconTransform=rTrans;
			
			// Adjust for orientations
			switch (interfaceOrientation){
				case UIInterfaceOrientationPortraitUpsideDown:iconTransform=CGAffineTransformRotate(rTrans,DEGREES_TO_RADIANS(180));break;
				case UIInterfaceOrientationLandscapeLeft:iconTransform=CGAffineTransformRotate(rTrans,DEGREES_TO_RADIANS(270));break;
				case UIInterfaceOrientationLandscapeRight:iconTransform=CGAffineTransformRotate(rTrans,DEGREES_TO_RADIANS(90));break;
			}
			
			/*int iconNumber=[self calculateIconNumber];
			for (UIView *theView in trayView.subviews){
				if ([theView isKindOfClass:[UIImageView class]]){
					//theView.transform=CGAffineTransformIdentity;
					
					if (theView.tag!=100+iconNumber){
						//[theView setFrame:CGRectMake(10,10+(theView.tag*55),40,40)];
						//[theView.layer setCornerRadius:20];
						[theView setAlpha:0.25];
					}else{
						//[theView setFrame:CGRectMake(5,5+(theView.tag*55),50,50)];
						//[theView.layer setCornerRadius:25];
						[theView setAlpha:1.0];
					}
					
					theView.transform=iconTransform;
				}
			}*/
			
			// Handle scrolling
			capHeight=-1;
			if ([abutton getToggleForKey:@"scrollEnabled"]){
				if ((touchLocation.x>=[[UIScreen mainScreen] bounds].size.width-60 && touchLocation.x>abWin.frame.origin.x) || (touchLocation.x<=60 && touchLocation.x<abWin.frame.origin.x) || (touchLocation.y>=[[UIScreen mainScreen] bounds].size.height-60 && touchLocation.y>abWin.frame.origin.y) || (touchLocation.y<=60 && touchLocation.y<abWin.frame.origin.y)){
					capHeight=newHeight-60;
				}
			
				float requestedHeight=sqrt(pow(originToTouchX,2)+pow(originToTouchY,2));
				if (capHeight>0 && requestedHeight>capHeight){
					heightForScroll=newHeight;
					if (!isExpanding){
						[self stopScrolling];
						[self scrollToEnd];
					}
				}else if (newHeight<180){
					if (!isShrinking){
						[self stopScrolling];
						[self scrollToBeginning];
					}
				}else{
					[self stopScrolling];
				}
			}
			
			
			// Handle multitasking clear
			if ([abutton getToggleForKey:@"killApps"]){
				if (currentView==0){
					if ([abutton identifiers]!=nil && [[abutton identifiers] count]>0){
						if ([abutton getToggleForKey:@"scrollEnabled"]){
							if ((capHeight==-1 && newHeight>=maxTrayHeight) || (capHeight>-1 && trayView.contentOffset.y>=(maxTrayHeight-capHeight-100))){
								if (!clearTrayWaiting){
									clearTrayWaiting=YES;
									[self performSelector:@selector(triggerClearMultitaskingTray) withObject:nil afterDelay:1.5];
								}
							}else{
								clearTrayWaiting=NO;
								[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(triggerClearMultitaskingTray) object:nil];
					
								if (willDestroyMultitasking){
									[self clearMultitaskingTrigger];
								}
							}
						}else{
							if (newHeight>=maxTrayHeight){
								if (!clearTrayWaiting){
									clearTrayWaiting=YES;
									[self performSelector:@selector(triggerClearMultitaskingTray) withObject:nil afterDelay:1.5];
								}
							}else{
								clearTrayWaiting=NO;
								[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(triggerClearMultitaskingTray) object:nil];
					
								if (willDestroyMultitasking){
									[self clearMultitaskingTrigger];
								}
							}
						}
					}
				}else{
					if (clearTrayWaiting){
						clearTrayWaiting=NO;
						[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(triggerClearMultitaskingTray) object:nil];
					}
				
					if (willDestroyMultitasking){
						[self clearMultitaskingTrigger];
					}
				}
			}
			
			[self setFrame:CGRectMake(self.frame.origin.x,self.frame.origin.y,60,newHeight)];
			
			CGPoint offset=trayView.contentOffset;
			if (offset.y>(maxTrayHeight-capHeight-60)) offset.y=maxTrayHeight-capHeight-60;
			if (didRelayout) offset.y=0;
			
			[trayView setFrame:CGRectMake(trayView.frame.origin.x,trayView.frame.origin.y,60,newHeight-60)];
			[trayView setContentOffset:offset];
			
			int iconNumber=[self calculateIconNumber];
			for (UIView *theView in trayView.subviews){
				if ([theView isKindOfClass:[UIImageView class]]){
					//theView.transform=CGAffineTransformIdentity;
					
					if ([abutton getToggleForKey:@"highlightApp"]){
						if (theView.tag!=100+iconNumber){
							//[theView setFrame:CGRectMake(10,10+(theView.tag*55),40,40)];
							//[theView.layer setCornerRadius:20];
							[theView setAlpha:0.25];
						}else{
							//[theView setFrame:CGRectMake(5,5+(theView.tag*55),50,50)];
							//[theView.layer setCornerRadius:25];
							[theView setAlpha:1.0];
						}
					}
					
					theView.transform=iconTransform;
				}
			}
			
			// Manipulate the icon view as well
			iconImageView.transform=CGAffineTransformIdentity;
			iconImageView.transform=iconTransform;
			
		}else{
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unlockOpenTray) object:nil];
			
			CGRect newFrame=CGRectMake(touchLocation.x-30,touchLocation.y-30,60,60);
			
			// Handle dockToScreenEdge
			if ([abutton getToggleForKey:@"dockToEdge"]){
				if (touchLocation.y<60){ // Top
					newFrame.origin.y=-30;
				}else if (touchLocation.y>[[UIScreen mainScreen] bounds].size.height-60){ // Bottom
					newFrame.origin.y=[[UIScreen mainScreen] bounds].size.height-30;
				}else if (touchLocation.x<[[UIScreen mainScreen] bounds].size.width/2){ // Left
					newFrame.origin.x=-30;
				}else{ // Default to right
					newFrame.origin.x=[[UIScreen mainScreen] bounds].size.width-30;
				}
			}
			
			// Save coordinates and set newFrame
			[abutton savePosition:newFrame.origin];
			[abWin setFrame:newFrame];
		}
	}
	
	- (void)triggerClearMultitaskingTray{
		UILabel *theLabel;
		
		for (UIView *sub in trayView.subviews){
			if ([sub isKindOfClass:[UILabel class]]){
				theLabel=(UILabel *)sub;
			}
		}
		
		if (theLabel!=nil){
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				//[theLabel setTextColor:[UIColor redColor]];
				[theLabel setText:@"∅"];
			} completion:^(BOOL finished){
				willDestroyMultitasking=YES;
			}];
		}
	}
	
	- (void)clearMultitaskingTrigger{
		UILabel *theLabel;
		
		for (UIView *sub in trayView.subviews){
			if ([sub isKindOfClass:[UILabel class]]){
				theLabel=(UILabel *)sub;
			}
		}
		
		if (theLabel!=nil){
			[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
				//[theLabel setTextColor:[UIColor redColor]];
				[theLabel setText:@"↑"];
			} completion:^(BOOL finished){
				willDestroyMultitasking=NO;
			}];
		}
	}
		
	
	- (void)scrollToEnd{
		if (trayView.contentOffset.y<(maxTrayHeight-capHeight-60)){
			isExpanding=YES;
			[trayView setContentOffset:CGPointMake(0,trayView.contentOffset.y+2)];
			[self performSelector:@selector(scrollToEnd) withObject:nil afterDelay:0.01];
		}
	}
	
	- (void)scrollToBeginning{
		if (trayView.contentOffset.y>0){
			isShrinking=YES;
			[trayView setContentOffset:CGPointMake(0,trayView.contentOffset.y-2)];
			[self performSelector:@selector(scrollToBeginning) withObject:nil afterDelay:0.01];
		}
	}
	
	- (void)stopScrolling{
		isExpanding=NO;
		isShrinking=NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollToEnd) object:nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollToBeginning) object:nil];
	}
	
	// Lost touches
	- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
		[self clearTray];
		[self lockOpenTray];
		isPositionable=NO;
	}
	
	- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
		[abutton startNotificationCenter];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unlockMove) object:nil];
		
		if (!didSomething) [abutton simulateHomePress];
		if (willDestroyMultitasking){
			[self clearTray];
			[abutton killAllRunningApplications];
		}
		
		// Figure out if they selected an app
		if (isMovable && !isPositionable && !willDestroyMultitasking){
			
			float maxHeight=self.frame.size.height+trayView.contentOffset.y-60;
			int iconNumber=[self calculateIconNumber];
			
			if ((maxTrayHeight-maxHeight)<80 || maxHeight<=10 || iconNumber<0){
				// Close tray, just ignore silently
			}else{
				NSMutableArray *icons=[abutton icons];
				if (currentView==1) icons=favoriteIcons;
				
				NSMutableArray *bundles=[abutton identifiers];
				if (currentView==1) bundles=filteredFavBundles;
				
				if ([bundles count]-1>=iconNumber){
					if ([icons count]-1>=iconNumber){
						[iconImageView.layer setBorderWidth:1.0];
						[iconImageView setImage:[icons objectAtIndex:iconNumber]];
					}else{
						NSLog(@"!--- Missing icons: %@",icons);
					}
				
					[UIView animateWithDuration:0.5 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
						[iconImageView.layer setBorderWidth:0.0];
						[iconImageView setAlpha:0.0];
					} completion:^(BOOL finished){
						[iconImageView setImage:nil];
						[iconImageView setAlpha:1.0];
					}];
					
					[abutton didPickApplication:[bundles objectAtIndex:iconNumber]];
				}
			}
			
			[self clearTray];
		}
		
		[self lockOpenTray];
		isPositionable=NO;
		/*isMovable=NO;
		[self setBackgroundColor:[UIColor whiteColor]];*/
	}
	
	- (int)calculateIconNumber{
		// When 50%+ of an icon is showing, then do that action...
		float maxHeight=self.frame.size.height+trayView.contentOffset.y-60;
		int iconNumber=ceil(maxHeight/55);
		iconNumber--;
		
		// Find remainder
		int remainder=(int)maxHeight%55;
		if (remainder>30) iconNumber++;
		
		iconNumber--;
		
		if ([abutton getToggleForKey:@"sausageFingers"]) iconNumber--;
		
		return iconNumber;
	}
	
	- (void)unlockMove{
		isPositionable=YES;
		if ([abutton getToggleForKey:@"blurEnabled"]){
			if ([abutton getToggleForKey:@"blackButton"]){
				[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
			}else{
				[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
			}
		}else{
			if ([abutton getToggleForKey:@"blackButton"]){
				[self setBackgroundColor:[UIColor blackColor]];
			}else{
				[self setBackgroundColor:[UIColor whiteColor]];
			}
		}
	}
	
	- (void)unlockOpenTray{
		if ([abutton getToggleForKey:@"swapControls"]) isPositionable=NO;
		
		if ([abutton getToggleForKey:@"blurEnabled"]){
			if ([abutton getToggleForKey:@"blackTray"]){
				[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
			}else{
				[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
			}
		}else{
			if ([abutton getToggleForKey:@"blackTray"]){
				[self setBackgroundColor:[UIColor blackColor]];
			}else{
				[self setBackgroundColor:[UIColor whiteColor]];
			}
		}
		
		isMovable=YES;
		[self layoutIcons:0];
		currentView=0;
	}
	
	- (void)layoutIcons:(int)type{
		capHeight=-1;
		[self stopScrolling];
		[trayView setContentOffset:CGPointZero animated:NO];
		
		filteredFavBundles=[abutton favoriteBundles];
		favoriteIcons=[abutton favoriteIcons];
		
		NSMutableArray *buns=[abutton identifiers];
		if (type==1) buns=[abutton favoriteBundles];
		
		NSMutableArray *icons=[abutton icons];
		if (type==1) icons=favoriteIcons;
		
		// Dump icons NAO
		int theIconNum=0;
		for (UIImage *theImage in icons){
			// Try to reuse an existing image view
			UIImageView *theImageView=(UIImageView *)[self viewWithTag:100+theIconNum];
			if (theImageView==nil){
				theImageView=[[UIImageView alloc] initWithFrame:CGRectMake(5,5+(theIconNum*55),50,50)];
				
				[theImageView setContentMode: UIViewContentModeScaleToFill];
				
				[theImageView setClipsToBounds:YES];
				[theImageView.layer setCornerRadius:theImageView.bounds.size.width/2];
				[theImageView.layer setMasksToBounds:YES];
				[theImageView setTag:100+theIconNum];
			
				[trayView addSubview:theImageView];
			}
			
			[theImageView.layer setBorderWidth:1.0];
			
			if ([abutton getToggleForKey:@"highlightApp"]){
				[theImageView setAlpha:0.25];
			}else{
				[theImageView setAlpha:1.0];
			}
			
			
			[theImageView setImage:theImage];
			
			if ([cachedColors objectForKey:[buns objectAtIndex:theIconNum]]==nil){
				[cachedColors setObject:[theImage colorAtPixel:CGPointMake(50,10)] forKey:[buns objectAtIndex:theIconNum]];
			}
		
			UIColor *iconColor=(UIColor *)[cachedColors objectForKey:[buns objectAtIndex:theIconNum]];
		
			[theImageView.layer setBorderColor:iconColor.CGColor];
			
			[theImageView.layer setShouldRasterize:YES];
			
			theIconNum++;
		}
		
		// Clear up remaining UIViews
		/*for (UIView *theView in self.subviews){
			if ([theView isKindOfClass:[UIImageView class]] && theView.tag>=100+theIconNum-1){
				[theView removeFromSuperview];
			}
		}*/
		
		if ([abutton getToggleForKey:@"sausageFingers"]) theIconNum++;
		
		// Make close tray button
		UILabel *theCloseLabel=[[UILabel alloc] initWithFrame:CGRectMake(5,5+(theIconNum*55),50,50)];
		[theCloseLabel setAlpha:0.5];
		[theCloseLabel setFont:[UIFont systemFontOfSize:18]];
		[theCloseLabel setTextAlignment:NSTextAlignmentCenter];
		[theCloseLabel setText:@"↑"];
		[theCloseLabel setTextColor:[UIColor lightGrayColor]];
		[trayView addSubview:theCloseLabel];
		
		// Set max tray height
		maxTrayHeight=65+(theIconNum*55)+55;
	}
	
	- (void)lockOpenTray{
		isMovable=NO;
		
		[UIView animateWithDuration:0.25 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
			[trayView setContentOffset:CGPointZero];
			[trayView setFrame:CGRectMake(trayView.frame.origin.x,trayView.frame.origin.y,60,60)];
			[self setFrame:CGRectMake(self.frame.origin.x,self.frame.origin.y,60,60)];
			
			if ([abutton getToggleForKey:@"blurEnabled"]){
				//[blurView setFrame:CGRectMake(0,0,60,60)];
				[[abutton effectView] setFrame:CGRectMake(0,0,60,60)];
			}else{
				if ([abutton getToggleForKey:@"blackButton"]){
					[self setBackgroundColor:[UIColor blackColor]];
				}else{
					[self setBackgroundColor:[UIColor whiteColor]];
				}
			}
			
			[self setAlpha:[abutton getFloatForKey:@"restingAlpha"]];
			
			if ([abutton getFloatForKey:@"restingAlpha"]<=0.01){
				[self.layer setBorderWidth:0.0];
			}else{
				[self.layer setBorderWidth:1.0];
			}
			
			if (![abutton getToggleForKey:@"borderEnabled"]) [self.layer setBorderWidth:0.0];
		} completion:^(BOOL finished){
			// Un-transform!
			iconImageView.transform=CGAffineTransformIdentity;
			self.superview.transform=CGAffineTransformIdentity;
			
			// Fix muddled superview frame
			CGRect theFrame=self.superview.frame;
			theFrame.size.height=60;
			theFrame.size.width=60;
			[self.superview setFrame:theFrame];
			
			if ([abutton getToggleForKey:@"blurEnabled"]){
				if ([abutton getToggleForKey:@"blackButton"]){
					[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
				}else{
					[[abutton effectView] _setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
				}
			}
		}];
	}
	
	- (void)clearTray{
		// Remove all UIImageView's
		for (UIView *theView in trayView.subviews){
			if ([theView isKindOfClass:[UIImageView class]]){
				if (theView.tag!=1337){
					// Make reusable
					[(UIImageView *)theView setImage:nil];
					[theView.layer setShouldRasterize:NO];
					[theView.layer setBorderWidth:0.0];
					//[theView setAlpha:0.0];
				}
			}else if ([theView isKindOfClass:[UILabel class]]){
				[theView removeFromSuperview];
			}
		}
	}
	
	- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
		if ([self alpha]<0.1){
			return self;
		}else{
			return [super hitTest:point withEvent:event];
		}
	}
@end