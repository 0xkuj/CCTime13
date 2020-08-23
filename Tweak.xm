/* This tweak will add a clock to your control center for easy access.
 * Clock position is configurable from settings 
 * Made by: 0xkuj */
//#include <RemoteLog.h>
#define GENERAL_PREFS @"/var/mobile/Library/Preferences/com.0xkuj.cctime13pref.plist"

static float XaxisREG = -1;
static float YaxisREG = -1;
static float XaxisORI = -1;
static float YaxisORI = -1;
BOOL posCalcREG = FALSE;
BOOL posCalcORI = FALSE;
static int countREG;
static int countORI;
UILabel *CCTime;
static BOOL isEnabled;
int labelSize = 100;
static BOOL dismissingCC = FALSE;


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
}

/* Calculate status bar changes when the status bar is ready in the CC */
%hook _UIStatusBarForegroundView 
- (void)layoutSubviews {
	%orig;
	if (!isEnabled) {
        return;	
	}
	if (posCalcREG){
		if (XaxisREG == -1)
			XaxisREG = self.center.x/1.20; 
		if (YaxisREG == -1)
			YaxisREG = self.center.y/1.85;
		posCalcREG = FALSE;
		countREG++;
	} else if (posCalcORI) {
		if (XaxisORI == -1)
			XaxisORI = self.center.x/1.20; 
		if (YaxisORI == -1)
			YaxisORI = self.center.y/1.85;
		posCalcORI = FALSE;
		countORI++;
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
	/*
	NSDateFormatter* estDf = [[NSDateFormatter alloc] init];
	[estDf setDateFormat:@"dd/MM"];
	NSString *timeStr = [estDf stringFromDate:[NSDate date]];
	*/
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];

	if (CCTime) {
		[CCTime removeFromSuperview];
	}		
	if (currOrientation == UIDeviceOrientationPortrait) {
		CCTime = [[UILabel alloc] initWithFrame:CGRectMake(XaxisREG, YaxisREG, labelSize, 20)];
	}
	else {
		CCTime = [[UILabel alloc] initWithFrame:CGRectMake(XaxisORI, YaxisORI, labelSize, 20)];
	}
	/*
	[CCTime setTextColor:[UIColor whiteColor]];
	[CCTime setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]];
	NSString* time = [formatter stringFromDate:[NSDate date]];
	NSString* date = timeStr;
	CCTime.numberOfLines = 0;
	CCTime.text = [NSString stringWithFormat:@"%@\n%@", time, date];
	[formatter release];
	CCTime.textAlignment = NSTextAlignmentCenter;
	[self addSubview:CCTime];
	*/
	[CCTime setTextColor:[UIColor whiteColor]];
	[CCTime setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]];
	CCTime.text = [formatter stringFromDate:[NSDate date]];
	[formatter release];
	CCTime.textAlignment = NSTextAlignmentCenter;
	[self addSubview:CCTime];
					
	%orig;
}
%end

%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.cctime13pref.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}