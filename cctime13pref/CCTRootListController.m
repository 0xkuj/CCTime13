#include "CCTRootListController.h"
#include <RemoteLog.h>
#include <spawn.h>

@interface UIScreen (kuj)
-(CGRect)_boundsForInterfaceOrientation:(long long)arg1 ;
@end

@implementation CCTRootListController
/* variable to take the edge of the screen */
int labelSize = 75;
/* load all specifiers from plist file */
- (NSMutableArray*)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
		[self applyModificationsToSpecifiers:(NSMutableArray*)_specifiers];
	}

	return (NSMutableArray*)_specifiers;
}

- (void)loadView {
    [super loadView];
    ((UITableView *)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

-(void)_returnKeyPressed:(id)arg1 {
    [self.view endEditing:YES];
}

/* actually remove them when disabled */
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			BOOL enabled = [[self readPreferenceValue:specifier] boolValue];
			if(!enabled)
			{
				NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange([_allSpecifiers indexOfObject:specifier]+1, [nestedEntryCount intValue])] mutableCopy];

				BOOL containsNestedEntries = NO;

				for(PSSpecifier* nestedEntry in nestedEntries)	{
					NSNumber* nestedNestedEntryCount = [[nestedEntry properties] objectForKey:@"nestedEntryCount"];
					if(nestedNestedEntryCount)	{
						containsNestedEntries = YES;
						break;
					}
				}

				if(containsNestedEntries)	{
					[self removeDisabledGroups:nestedEntries];
				}

				[specifiers removeObjectsInArray:nestedEntries];
			}
		}
	}
}

/* save a copy of those specifications so we can retrieve them later */
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	_allSpecifiers = [specifiers copy];
	[self removeDisabledGroups:specifiers];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}
- (id)applyImmediateModificationToSpecifier:(id)value specifier:(PSSpecifier*)specifier newval:(float)newValue
{
		value = [NSNumber numberWithFloat:newValue];
		[self setPreferenceValue:value specifier:specifier];
		[self reloadSpecifierID:specifier.identifier animated:YES];
		value = [NSNumber numberWithFloat:newValue-labelSize];
		[self setPreferenceValue:value specifier:specifier];
		[self reloadSpecifierID:specifier.identifier animated:YES];
		return value;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	/* very ugly hack to have the specifier thinks he changes his value. will fix that later on (lol) */
	float newValue = -1;
	if ([specifier.identifier isEqualToString:@"styleSeparator"]) {
		value = ([(NSString *)value isEqual:@""]) ? @"/" : [value substringToIndex:1];
	} else if ([specifier.identifier isEqualToString:@"XAXISREG"] && [value floatValue] > [UIScreen mainScreen].bounds.size.width) {
		newValue = [UIScreen mainScreen].bounds.size.width;
	} else if ([specifier.identifier isEqualToString:@"YAXISREG"] && [value floatValue] > [UIScreen mainScreen].bounds.size.height) {
		newValue = [UIScreen mainScreen].bounds.size.height-30;
	} else if ([specifier.identifier isEqualToString:@"XAXISORI"] && 
				[value floatValue] > [[UIScreen mainScreen] _boundsForInterfaceOrientation:UIDeviceOrientationLandscapeRight].size.width) {
		newValue = [[UIScreen mainScreen] _boundsForInterfaceOrientation:UIDeviceOrientationLandscapeRight].size.width;
	} else if ([specifier.identifier isEqualToString:@"YAXISORI"] &&
				[value floatValue] > [[UIScreen mainScreen] _boundsForInterfaceOrientation:UIDeviceOrientationLandscapeRight].size.height) {
		newValue = [[UIScreen mainScreen] _boundsForInterfaceOrientation:UIDeviceOrientationLandscapeRight].size.height;	
	}
	if (newValue != -1) {
		value = [self applyImmediateModificationToSpecifier:value specifier:specifier newval:newValue];
	}
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}

	if(specifier.cellType == PSSwitchCell)	{
		NSNumber* numValue = (NSNumber*)value;
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)	{
			NSInteger index = [_allSpecifiers indexOfObject:specifier];
			NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
			[self removeDisabledGroups:nestedEntries];

			if([numValue boolValue])  {
				[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
			}
			else  {
				[self removeContiguousSpecifiers:nestedEntries animated:YES];
			}
		}
	}
}

-(void)defaultsettings:(PSSpecifier*)specifier {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
    									                    message:@"This will restore CCTime Settings to default\nAre you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
				[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath: @"/var/mobile/Library/Preferences/com.0xkuj.cctime13pref.plist"] error: nil];
    			[self reload];
    			CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    			CFNotificationCenterPostNotification(r, (CFStringRef)@"com.0xkuj.cctime13pref.settingschanged", NULL, NULL, true);
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice"
				message:@"Settings restored to default\nPlease respring your device" 
				preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction* DoneAction =  [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
    			handler:^(UIAlertAction * action) {
					return;
				}];
				[alert addAction:DoneAction];
				[self presentViewController:alert animated:YES completion:nil];
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
	return;
}

- (void)respring:(id)sender {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Respring"
    									                    message:@"Are you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
			pid_t pid;
			const char* args[] = {"killall", "backboardd", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
}

-(void)openTwitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/omrkujman"]];
}

-(void)donationLink {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/0xkuj"]];
}

@end