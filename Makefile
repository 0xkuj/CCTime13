#ARCHS = arm64e arm64 armv7
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCTime13
CCTime13_FILES = Tweak.xm
CCTime13_LIBRARIES = colorpicker
CCTime13_CFLAGS = -fobjc-arc


include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += cctime13pref
include $(THEOS_MAKE_PATH)/aggregate.mk
