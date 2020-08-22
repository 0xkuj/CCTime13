include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCTime13Pref
CCTime13Pref_FILES = CCTRootListController.m
CCTime13Pref_INSTALL_PATH = /Library/PreferenceBundles
CCTime13Pref_FRAMEWORKS = UIKit
CCTime13Pref_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CCTime13Pref.plist$(ECHO_END)
