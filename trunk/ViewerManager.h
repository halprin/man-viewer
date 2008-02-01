/* ViewerManager */

#import <Cocoa/Cocoa.h>
#import "Loader.h"
#import "Preferences.h"

@interface ViewerManager : NSObject
{
    IBOutlet NSTableView *entries;
    IBOutlet NSPopUpButton *filter;
    IBOutlet NSSearchField *searcher;
    IBOutlet NSTextView *viewer;
	IBOutlet NSWindow *window;
	IBOutlet Loader *loader;
	IBOutlet Preferences *preferences;
	NSMutableArray *manlist;
	NSMutableArray *searchDirectories;
}
-(ViewerManager*)init;
-(int)numberOfRowsInTableView: (NSTableView*)aTableView;
-(id)tableView: (NSTableView*)aTableView objectValueForTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex;
-(void)tableView: (NSTableView*)aTableView setObjectValue: (id)anObject forTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex;
-(void)addEntry: (NSString*)name withReload: (BOOL)flag;
-(void)applicationDidFinishLaunching: (NSNotification*)notification;
-(void)applicationWillTerminate: (NSNotification*)notification;
-(IBAction)showPreferences: (id)sender;
-(IBAction)update: (id)sender;
-(void)load;
-(void)dealloc;
@end
