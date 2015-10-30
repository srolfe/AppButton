export ARCHS = armv7 armv7s arm64
export ADDITIONAL_OBJCFLAGS = -fobjc-arc

#PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include theos/makefiles/common.mk

TWEAK_NAME = AppButton
AppButton_FILES = Tweak.xm ABWindow.m ABButtonView.m UIImage+ColorAtPixel.m
AppButton_FRAMEWORKS = UIKit CoreGraphics QuartzCore
AppButton_LDFLAGS = -weak_library theos/lib/libactivator.dylib
AppButton_PRIVATE_FRAMEWORKS = BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += appbuttonprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
