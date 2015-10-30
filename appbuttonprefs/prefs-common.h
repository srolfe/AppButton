typedef enum PSCellType {
	PSGroupCell,
	PSLinkCell,
	PSLinkListCell,
	PSListItemCell,
	PSTitleValueCell,
	PSSliderCell,
	PSSwitchCell,
	PSStaticTextCell,
	PSEditTextCell,
	PSSegmentCell,
	PSGiantIconCell,
	PSGiantCell,
	PSSecureEditTextCell,
	PSButtonCell,
	PSEditTextViewCell,
} PSCellType;

@interface PSTableCell : UITableViewCell
	//-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3;
	- (id)initWithSpecifier:(id)specifier;
	- (id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(id)specifier;
	-(void)setIcon:(id)icon;
	
@end

@interface PSListController : UITableViewController{
	UITableView *_table;
	id _specifiers;
}
	- (id)specifiers;
	- (id)loadSpecifiersFromPlistName:(id)arg1 target:(id)arg2;
	- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
	- (void)_moveSpecifierAtIndex:(unsigned int)arg1 toIndex:(unsigned int)arg2 animated:(BOOL)arg3;
	- (int)indexOfSpecifier:(id)arg1;
	- (int)indexOfGroup:(int)arg1;
	- (void)beginUpdates;
	- (void)endUpdates;
	
	- (void)insertSpecifier:(id)arg1 atEndOfGroup:(int)arg2;
	- (void)removeSpecifierAtIndex:(int)arg1;
	
	- (UITableView *)table;
	
	- (id)specifierAtIndex:(int)arg1;
	- (int)indexForIndexPath:(id)arg1;
	- (id)indexPathForSpecifier:(id)arg1;
	- (id)indexPathForIndex:(int)arg1;
	
	- (void)_moveSpecifierAtIndex:(unsigned int)arg1 toIndex:(unsigned int)arg2 animated:(BOOL)arg3;
	- (NSArray *)specifiersInGroup:(int)arg1;
	- (int)indexOfGroup:(int)arg1;
	- (void)insertSpecifier:(id)arg1 atEndOfGroup:(int)arg2;
	
	-(void)reload;
	-(void)reloadSpecifiers;
@end
	

@interface PSSpecifier : NSObject{
    id target;
    SEL getter;
    SEL setter;
    
    SEL cancel;
    Class detailControllerClass;
    long long cellType;
    Class editPaneClass;
    long long keyboardType;
    long long autoCapsType;
    long long autoCorrectionType;
    unsigned long long textFieldType;
    NSString *_name;
    NSArray *_values;
    NSDictionary *_titleDict;
    NSDictionary *_shortTitleDict;
    id _userInfo;
    NSMutableDictionary *_properties;
    SEL _confirmationAction;
    SEL _confirmationCancelAction;
    SEL _buttonAction;
    SEL _controllerLoadAction;
    _Bool _showContentString;
	
	@public
	SEL action;
}
	@property(retain, nonatomic) NSString *name; 
	+ (long long)keyboardTypeForString:(id)arg1;
	+ (long long)autoCapsTypeForString:(id)arg1;
	+ (long long)autoCorrectionTypeForNumber:(id)arg1;
	+ (id)emptyGroupSpecifier;
	+ (id)groupSpecifierWithName:(id)arg1;
	+ (id)preferenceSpecifierNamed:(id)arg1 target:(id)arg2 set:(SEL)arg3 get:(SEL)arg4 detail:(Class)arg5 cell:(long long)arg6 edit:(Class)arg7;
	- (id)description;
	- (void)dealloc;
	- (void)setValues:(id)arg1 titles:(id)arg2 shortTitles:(id)arg3 usingLocalizedTitleSorting:(_Bool)arg4;
	- (void)setValues:(id)arg1 titles:(id)arg2 shortTitles:(id)arg3;
	- (void)setValues:(id)arg1 titles:(id)arg2;
	- (id)properties;
	- (void)setProperties:(id)arg1;
	- (void)removePropertyForKey:(id)arg1;
	- (void)setProperty:(id)arg1 forKey:(id)arg2;
	- (id)propertyForKey:(id)arg1;
	- (id)init;
	@property(retain, nonatomic) NSString *identifier;
@end
	
@interface PSControlTableCell : PSTableCell
	-(UIControl *)control;
@end
	
@interface PSSwitchTableCell : PSControlTableCell
	-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 ;
@end
	
@interface PSSliderTableCell : PSControlTableCell
	-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 ;
@end
	
@interface PSSegmentTableCell : PSControlTableCell
	-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 ;
@end