#import "prefs-common.h"

@interface ABAboutTableCell : PSTableCell{ //<PreferencesTableCustomView>
	UILabel *_label;
	UILabel *_jobText;
	UIImageView *_personImage;
}
@end
 
@implementation ABAboutTableCell
 
	-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 { //init method
		self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3]; //call the super init method
		if (self) {
			NSString *personPath=[[NSBundle bundleForClass:[self class]] pathForResource:@"steverolfe" ofType:@"png"];
			_personImage=[[UIImageView alloc] initWithFrame:CGRectMake(10,10,50,50)];
			[_personImage setImage:[UIImage imageWithContentsOfFile:personPath]];
			[_personImage setClipsToBounds:YES];
			[_personImage.layer setCornerRadius:_personImage.bounds.size.width/2];
			[_personImage.layer setMasksToBounds:YES];
			[_personImage.layer setBorderWidth:1.0];
			[_personImage.layer setBorderColor:[UIColor whiteColor].CGColor];
			[self addSubview:_personImage];
			
			
			CGRect frame = [self frame];
			frame.origin=CGPointMake(70,2);
			
			_label = [[UILabel alloc] initWithFrame:frame];
			
			NSMutableAttributedString *attributedString=[[NSMutableAttributedString alloc] initWithString:@"Steve Rolfe @Chewmieser"];
			[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:24] range:NSMakeRange(0, 12)];
			[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24] range:NSMakeRange(12, 11)];
			
			[_label setAttributedText:attributedString];
			[_label setBackgroundColor:[UIColor clearColor]];
			[_label setShadowColor:[UIColor whiteColor]];
			[_label setShadowOffset:CGSizeMake(0,1)];
			[_label setTextAlignment:NSTextAlignmentLeft];
 
			[self addSubview:_label];
			
			frame.origin=CGPointMake(70,27);
			_jobText = [[UILabel alloc] initWithFrame:frame];
			
			[_jobText setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:18]];
			[_jobText setText:@"Developer"];
			[_jobText setBackgroundColor:[UIColor clearColor]];
			[_jobText setShadowColor:[UIColor whiteColor]];
			[_jobText setShadowOffset:CGSizeMake(0,1)];
			[_jobText setTextAlignment:NSTextAlignmentLeft];
 
			[self addSubview:_jobText];
		}
		return self;
	}
 
@end