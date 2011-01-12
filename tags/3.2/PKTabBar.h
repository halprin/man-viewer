//
//  PKTabView.h
//  Man Viewer
//
//  Created by Peter Kendall on 11/3/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PKTab.h"


@interface PKTabBar : NSView
{
	NSMutableArray* tabs;
	PKTab* selectedTab;
	NSPopUpButton* dropDownMenu;
	NSUInteger nextSelectTab;
	NSUInteger hideIndex;
	NSUInteger numberHiddenTabs;
	id delegate;
}
-(PKTabBar*)initWithFrame: (NSRect)frameRect;
-(void)setDelegate: (id)newDelegate;
-(void)addTabWithTitle: (NSString*)title;
-(void)setSelectedTabTitle: (NSString*)newTitle;
-(void)selectTabAtIndex: (NSUInteger)index;
-(void)closeTabAtIndex: (NSUInteger)index;
-(NSUInteger)selectedTabIndex;
-(NSUInteger)tabCount;
-(NSUInteger)numberVisibleTabs;
-(NSUInteger)numberHiddenTabs;
@end
