export ARCHS = armv7 armv7s arm64
export ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

BUNDLE_NAME = appbuttonprefs
appbuttonprefs_FILES = appbuttonprefs.mm ABPrefsHeaderCell.m ABSwitchTableCell.m ABFavoritedAppsController.m ABLookAndFeelController.m ABBehaviorController.m ABAboutController.m SAMultisectorControl.m SAMath.m ABWhitelistApps.m ABSegmentTableCell.m ABAboutTableCell.m ABAboutKyleTableCell.m
appbuttonprefs_INSTALL_PATH = /Library/PreferenceBundles
appbuttonprefs_FRAMEWORKS = UIKit CoreGraphics
appbuttonprefs_PRIVATE_FRAMEWORKS = Preferences
appbuttonprefs_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/appbuttonprefs.plist$(ECHO_END)
	$(ECHO_NOTHING)sudo chown root:wheel $(THEOS_STAGING_DIR)/Library/PreferenceBundles/appbuttonprefs.bundle$(ECHO_END)
	$(ECHO_NOTHING)sudo chown -R root:wheel $(THEOS_STAGING_DIR)/Library/PreferenceBundles/appbuttonprefs.bundle/*$(ECHO_END)