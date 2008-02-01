//
//  Preferences.h
//  Man Viewer
//
//  Created by Peter Kendall on 1/31/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Preferences : NSObject
{
	IBOutlet NSTableView *entries;
	IBOutlet NSTextField *adder;
	IBOutlet NSWindow *window;
	NSMutableArray *newOne;
	NSMutableArray **original;
}
-(int)numberOfRowsInTableView: (NSTableView*)aTableView;
-(id)tableView: (NSTableView*)aTableView objectValueForTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex;
-(void)tableView: (NSTableView*)aTableView setObjectValue: (id)anObject forTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex;
-(void)addEntry: (NSString*)name withReload: (BOOL)flag;
-(IBAction)add:(id)sender;
-(IBAction)delete:(id)sender;
-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;
-(NSWindow*)window;
-(void)setOriginal: (NSMutableArray**)theOriginal;
-(void)loadOriginal;
-(void)dealloc;
@end
