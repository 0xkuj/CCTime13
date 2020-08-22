#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>




@interface CCTRootListController : PSListController {
    NSArray* _allSpecifiers;
}
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers;
- (id)applyImmediateModificationToSpecifier:(id)value specifier:(PSSpecifier*)specifier newval:(float)newValue;
- (void)defaultsettings:(PSSpecifier*)specifier ;
- (void)openTwitter;
- (void)donationLink;
@end
