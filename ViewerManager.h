/* ViewerManager */

#import <Cocoa/Cocoa.h>
#import "Loader.h"
#import "Preferences.h"
#import "ManEntry.h"
#import "TabCollectionView.h"
#import "TabDropdownView.h"

@interface ViewerManager : NSObject
{
    IBOutlet NSTableView* entries;
    IBOutlet NSPopUpButton* filter;
    IBOutlet NSSearchField* searcher;
    IBOutlet NSTextView* viewer;
	IBOutlet NSWindow* window;
	IBOutlet Loader* loader;
	IBOutlet Preferences* preferences;
	IBOutlet NSArrayController* manlist;
	NSMutableArray *searchDirectories;
	//IBOutlet TabCollectionView* tabs;
	//IBOutlet TabDropdownView* dropdown;
	BOOL loaded;
	NSString* searchString;
	NSString* filterString;
	NSMutableArray* cache;  //a list of all the man entries
}
-(ViewerManager*)init;
-(void)tableViewSelectionDidChange: (NSNotification*)notification;
-(void)addEntry: (NSString*)name withSection: (NSString*)section andPath: (NSString*)path;
-(void)applicationDidFinishLaunching: (NSNotification*)notification;
-(void)applicationWillTerminate: (NSNotification*)notification;
-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)theApplication;
-(CGFloat)splitView: (NSSplitView *)sender constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset;
-(CGFloat)splitView: (NSSplitView *)sender constrainMaxCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset;
-(IBAction)showPreferences: (id)sender;
-(void)changeTab: (NSNotification*)notification;
-(IBAction)saveText: (id)sender;
-(IBAction)savePDF: (id)sender;
-(void)savePanelDidEnd: (NSSavePanel*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo;
-(IBAction)search: (id)sender;
-(IBAction)filter: (id)sender;
-(IBAction)update: (id)sender;
-(void)loadFromCache;
-(void)loadFromDisk;
-(void)dealloc;
@end
