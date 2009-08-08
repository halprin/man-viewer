//
//  TabCollectionView.h
//  Man Viewer
//
//  Created by Peter Kendall on 3/30/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TabView.h"
#import "ManEntry.h"
#import "TabDropdownView.h";


@interface TabCollectionView : NSView
{
	TabView* currentTab;
	IBOutlet TabDropdownView* dropdown;
	int displayable;
}
-(IBAction)addTab: (id) sender;
-(IBAction)nextTab: (id)sender;
-(IBAction)previousTab: (id)sender;
-(void)tabToBeRemoved: (TabView*)sender;
-(TabView*)currentTab;
-(void)setCurrentTab: (TabView*)newValue;
-(void)dealloc;
@end
