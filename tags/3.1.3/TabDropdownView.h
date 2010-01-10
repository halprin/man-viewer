//
//  TabDropdownView.h
//  Man Viewer
//
//  Created by Peter Kendall on 5/26/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TabView.h"


@interface TabDropdownView : NSPopUpButton
{
	NSImage* dropDown;
	NSMutableArray* tabs;
}
-(void)push: (TabView*)tab;
-(void)itemSelected: (NSMenuItem*)sender;
-(TabView*)pop;
-(BOOL)hasItems;

@end
