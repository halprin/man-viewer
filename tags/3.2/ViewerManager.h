/* ViewerManager */

#import <Cocoa/Cocoa.h>
#import "Loader.h"
#import "Preferences.h"
#import "ManEntry.h"
#import "PAKTableView.h"
#import "IpcDelegate.h"
#import "PKTabBar.h"
#import "PKTextView.h"


static NSString* const PKNotificationManPagesLoaded=@"PKNotificationManPagesLoaded";

@interface ViewerManager : NSObject
{
    IBOutlet PAKTableView* entries;
    IBOutlet NSPopUpButton* filter;
    IBOutlet NSSearchField* searcher;
    IBOutlet PKTextView* viewer;
	IBOutlet NSWindow* window;
	IBOutlet Loader* loader;
	IBOutlet Preferences* preferences;
	IBOutlet NSArrayController* manlist;
	NSMutableArray* tabManList;
	NSMutableArray *searchDirectories;
	BOOL loaded;
	NSString* searchString;
	NSString* filterString;
	NSMutableArray* cache;  //a list of all the man entries
	IpcDelegate* ipcDelegate;
	IBOutlet PKTabBar* tabBar;
	IBOutlet NSMenuItem* closeWindowMenuItem;
	IBOutlet NSMenuItem* closeTabMenuItem;
}
-(ViewerManager*)init;
-(void)tableViewSelectionDidChange: (NSNotification*)notification;
-(void)displayManPageFromManEntry: (ManEntry*)entry;
-(NSString*)tableView: (NSTableView*)aTableView toolTipForCell: (NSCell*)aCell rect: (NSRectPointer)rect tableColumn: (NSTableColumn*)aTableColumn row: (NSInteger)row mouseLocation: (NSPoint)mouseLocation;
-(void)revealInFinder: (id)sender;
-(void)addEntry: (NSString*)name withSection: (NSString*)section andPath: (NSString*)path;
-(void)selectEntry: (NSString*)name withSection: (NSString*)section;
-(void)selectEntry: (ManEntry*)entry;
-(void)applicationDidFinishLaunching: (NSNotification*)notification;
-(void)applicationWillTerminate: (NSNotification*)notification;
-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)theApplication;
-(CGFloat)splitView: (NSSplitView *)sender constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset;
-(CGFloat)splitView: (NSSplitView *)sender constrainMaxCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset;
-(IBAction)showPreferences: (id)sender;
-(IBAction)installCommandLineTools: (id)sender;
-(void)authorizeInstall: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo;
-(IBAction)saveText: (id)sender;
-(IBAction)savePDF: (id)sender;
-(void)savePanelDidEnd: (NSSavePanel*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo;
-(IBAction)search: (id)sender;
-(IBAction)filter: (id)sender;
-(IBAction)newTab: (id)sender;
-(IBAction)closeTab: (id)sender;
-(IBAction)nextTab: (id)sender;
-(IBAction)previousTab: (id)sender;
-(IBAction)update: (id)sender;
-(void)loadManPages: (BOOL)cached;
-(void)loadFromCache;
-(void)loadFromDisk;
-(void)dealloc;
@end
