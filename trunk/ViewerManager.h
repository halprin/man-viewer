/* ViewerManager */

#import <Cocoa/Cocoa.h>
#import "Loader.h"
#import "Preferences.h"
#import "ManEntry.h"

@interface ViewerManager : NSObject
{
    IBOutlet NSTableView *entries;
    IBOutlet NSPopUpButton *filter;
    IBOutlet NSSearchField *searcher;
    IBOutlet NSTextView *viewer;
	IBOutlet NSWindow *window;
	IBOutlet Loader *loader;
	IBOutlet Preferences *preferences;
	IBOutlet NSArrayController* manlist;
	NSMutableArray *searchDirectories;
	BOOL loaded;
	NSString* searchString;
	NSString* filterString;
}
-(ViewerManager*)init;
-(void)tableViewSelectionDidChange: (NSNotification*)notification;
-(void)addEntry: (NSString*)name withSection: (NSString*)section;
-(void)applicationDidFinishLaunching: (NSNotification*)notification;
-(void)applicationWillTerminate: (NSNotification*)notification;
-(IBAction)showPreferences: (id)sender;
-(IBAction)search: (id)sender;
-(IBAction)filter: (id)sender;
-(IBAction)update: (id)sender;
-(void)load;
-(void)dealloc;
@end
