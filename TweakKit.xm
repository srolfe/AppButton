%hook UIScreen
	- (id)snapshotViewAfterScreenUpdates:(BOOL)arg1{
		[appButtonObject appButtonScreenshotHide];
		return %orig;
	}
%end
