/* This tweak will add a clock to your control center for easy access.
 * Clock position is configurable from settings 
 * Made by: 0xkuj */
#import <libcolorpicker.h>
#define GENERAL_PREFS @"/var/mobile/Library/Preferences/com.0xkuj.cctime13pref.plist"
#define UNSET_NUM -100
#define LABEL_WIDTH 100
#define LABEL_HEIGHT 45

static float XaxisREG = UNSET_NUM, YaxisREG = UNSET_NUM, XaxisORI = UNSET_NUM, YaxisORI = UNSET_NUM;
static BOOL isEnabled, dismissingCC = FALSE;
BOOL posCalcREG = FALSE, posCalcORI = FALSE, isBold = FALSE, setDate = FALSE, setAltDate = FALSE;
static int countREG, countORI;
int labelWidth = LABEL_WIDTH, labelHeight = LABEL_HEIGHT;
UILabel *CCTime;
UIColor* textColor;
UIFont* textFont;
NSString* textFontString,*dateSeparator,*colorHex;
float xcenterREG=0,ycenterREG=0,xcenterORI=0,ycenterORI=0,textSize;


@interface SBControlCenterController
-(BOOL)isPresented;
-(BOOL)isPresentedOrDismissing;
-(BOOL)isVisible;
@end

@interface _UIStatusBarForegroundView 
@property (assign, nonatomic) CGPoint center;
@end

@interface _UIStatusBar 
@property (nonatomic,retain) UIView * foregroundView;  
@end

@interface CCUIStatusBar : UIView
@end

@interface UIApplication ()
- (UIDeviceOrientation)_frontMostAppOrientation;
@end

/* Load preferences after change */
static void loadPrefs() {
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GENERAL_PREFS];
	isEnabled = [mainPreferenceDict objectForKey:@"isEnabled"] ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : YES;

	if ([mainPreferenceDict objectForKey:@"XAXISREG"] != nil) {
		XaxisREG = [[mainPreferenceDict objectForKey:@"XAXISREG"] floatValue];
	}

	if ([mainPreferenceDict objectForKey:@"YAXISREG"] != nil) {
		YaxisREG = [[mainPreferenceDict objectForKey:@"YAXISREG"] floatValue];
	}

	if ([mainPreferenceDict objectForKey:@"XAXISORI"] != nil) {
		XaxisORI = [[mainPreferenceDict objectForKey:@"XAXISORI"] floatValue];
	}
	if ([mainPreferenceDict objectForKey:@"YAXISORI"] != nil) {
		YaxisORI = [[mainPreferenceDict objectForKey:@"YAXISORI"] floatValue];
	}
	if ([mainPreferenceDict objectForKey:@"styleBold"] != nil) {
		isBold = [[mainPreferenceDict objectForKey:@"styleBold"] boolValue];
	}

	if ([mainPreferenceDict objectForKey:@"styleColor"] != nil) {
		colorHex = [mainPreferenceDict objectForKey:@"styleColor"];
	}
	
	if ([mainPreferenceDict objectForKey:@"styleSize"] != nil) {
		textSize = [[mainPreferenceDict objectForKey:@"styleSize"] floatValue];
	} else {
		textSize = 15.0f;
	}

	if ([mainPreferenceDict objectForKey:@"styleFont"] != nil) {
		textFontString = [mainPreferenceDict objectForKey:@"styleFont"];
		textFont = [UIFont fontWithName:textFontString size:textSize];
	} else {
		textFont = [UIFont systemFontOfSize:textSize weight:UIFontWeightMedium];
	}

	if ([mainPreferenceDict objectForKey:@"setDate"] != nil) {
		setDate =  [[mainPreferenceDict objectForKey:@"setDate"] boolValue];
	}
	dateSeparator = [mainPreferenceDict objectForKey:@"styleSeparator"] ? [mainPreferenceDict objectForKey:@"styleSeparator"] : @"/";

	if ([mainPreferenceDict objectForKey:@"setAltDate"] != nil) {
		setAltDate =  [[mainPreferenceDict objectForKey:@"setAltDate"] boolValue];
	}

}

/* Calculate status bar changes when the status bar is ready in the CC */
%hook _UIStatusBarForegroundView 
- (void)layoutSubviews {
	%orig;
	if (!isEnabled) {
        return;	
	}

	if (posCalcREG){
		posCalcREG = FALSE;
		countREG++;
		if (xcenterREG != 0)
		{
			return;
		}
		xcenterREG = self.center.x;
		ycenterREG = self.center.y;
	} else if (posCalcORI) {
		posCalcORI = FALSE;
		countORI++;
		if (xcenterORI != 0)
		{
			return;
		}
		xcenterORI = self.center.x;
		ycenterORI = self.center.y;
	}
}
%end

%hook SBControlCenterController
- (void)_willPresent {
	%orig;
	dismissingCC = FALSE;
}
- (void)_willDismiss {
	%orig;
	dismissingCC = TRUE;
	if (CCTime) {
		[CCTime removeFromSuperview];
	}
}
%end

/* Add the label of the clock */
%hook CCUIStatusBar
- (void)layoutSubviews {
	%orig;
	if (!isEnabled || dismissingCC) {
    	return;	
	}

	UIDeviceOrientation currOrientation = [[UIApplication sharedApplication] _frontMostAppOrientation];
	if (countREG < 2 && currOrientation == UIDeviceOrientationPortrait) {
		posCalcREG = TRUE;
		return;
	} else if (countORI < 2 && currOrientation != UIDeviceOrientationPortrait)
	{
		posCalcORI = TRUE;
		return;
	}

	if (CCTime) {
		[CCTime removeFromSuperview];
	}

	if (currOrientation == UIDeviceOrientationPortrait) {
		CCTime = [[UILabel alloc] initWithFrame:CGRectMake((XaxisREG != UNSET_NUM) ? XaxisREG : xcenterREG/1.20f, (YaxisREG != UNSET_NUM) ? YaxisREG : (setDate) ? ycenterREG/3.4f : 0, labelWidth, labelHeight)];
	}
	else {
		CCTime = [[UILabel alloc] initWithFrame:CGRectMake((XaxisORI != UNSET_NUM) ? XaxisORI : xcenterORI, (YaxisORI != UNSET_NUM) ? YaxisORI : (setDate) ? ycenterORI/3.4f : 0, labelWidth, labelHeight)];
	}

	NSString *dateString = @"";
	NSDateFormatter *clockFormatter = [[NSDateFormatter alloc] init];
    [clockFormatter setLocale:[NSLocale currentLocale]];
    [clockFormatter setDateStyle:NSDateFormatterNoStyle];
    [clockFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *time = [NSString stringWithFormat:@"%@\n", [clockFormatter stringFromDate:[NSDate date]]];

	if (setDate) {
		CCTime.numberOfLines = 0;
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		
		if (setAltDate) {
			[dateFormatter setDateFormat:[NSString stringWithFormat:@"dd%@MM",dateSeparator]];
		} else {
			NSString *localFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]];
			[dateFormatter setDateFormat:localFormat];
		}
		
		[dateFormatter setLocale:[NSLocale currentLocale]];
		NSDate *currentDate = [NSDate date];
		dateString = [dateFormatter stringFromDate:currentDate];
		[dateFormatter release];
	}

	/* setting the actual label text */
	CCTime.text = [time stringByAppendingString:dateString];

	if (isBold) {
		CCTime.attributedText=[[NSAttributedString alloc] 
		initWithString:CCTime.text
		attributes:@{
    	         NSStrokeWidthAttributeName: @-4.0
    	         }
		];
	}

	[CCTime setFont:textFont];
	CCTime.textColor = LCPParseColorString(colorHex, @"#FFFFFF");
	CCTime.textAlignment = NSTextAlignmentCenter;
	[clockFormatter release];
	[self addSubview:CCTime];
					
	%orig;
}
%end

%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.cctime13pref.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}