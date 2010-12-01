//
//  PKTabView.m
//  Man Viewer
//
//  Created by Peter Kendall on 11/3/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "PKTabView.h"
#import "PKTabCell.h"


@implementation PKTabView

-(PKTabView*)initWithFrame: (NSRect)frameRect
{
	if(self=[super initWithFrame: frameRect])
	{
		tabs=[[NSMutableArray alloc] init];
		selectedTab=nil;
		dropDownMenu=[[NSPopUpButton alloc] initWithFrame: NSMakeRect(0, 0, 26, 26) pullsDown: NO];
		[dropDownMenu setHidden: YES];
		[self addSubview: dropDownMenu];
		hideIndex=(([self frame].size.width-26)/106)-1;
		numberHiddenTabs=0;
		delegate=nil;
		//set myself up to emit notifications on me changing my frame
		[self setPostsFrameChangedNotifications: YES];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(frameResized:) name: NSViewFrameDidChangeNotification object: self];
		//add the default tab
		[self addTabWithTitle: @"Untitled"];
	}
	
	return self;
}

-(void)setDelegate: (id)newDelegate;
{
	if(delegate!=newDelegate)
	{
		//this is not the same object
		[delegate release];
		delegate=[newDelegate retain];
	}
}

-(void)addTabWithTitle: (NSString*)title
{
	PKTab* newTab=[[[PKTab alloc] initWithFrame: NSMakeRect(106*[self tabCount], 0, 106, 23)] autorelease];
	[newTab setTitle: title];
	//[newTab setToolTip: title];
	//set the delegate to ourself
	[newTab setDelegate: self];
	//actually add it
	[tabs addObject: newTab];
	[self addSubview: newTab];
	//test if this is the first tab, and if so, select it
	if([self tabCount]==1)
	{
		selectedTab=[newTab retain];
		//we were the first added tab, select it
		[newTab selectTab];
		//since this is the only tab, hide its close button since we don't want the possibility of 0 tabs
		[((PKTab*)[tabs objectAtIndex: 0]) hideCloseButton: YES];
	}
	else if([self tabCount]==2)
	{
		//this is the second tab, enable the first tab's close button
		[((PKTab*)[tabs objectAtIndex: 0]) hideCloseButton: NO];
	}
	//re-run the calculations to see if we should hide any tabs because this last added tab could of make it go out of the frame bounds of ourself
	//I need to incriment the hideIndex by one so that when I call frameResize it thinks that we shrunk and it needs to (potentially) hide some tabs
	hideIndex++;
	[self frameResized: nil];
}

-(void)setSelectedTabTitle: (NSString*)newTitle
{
	[selectedTab setTitle: newTitle];
	//now check to see if this tab is in the dropdown menu
	NSUInteger selectedIndex=[self selectedTabIndex];
	if(selectedIndex>([self numberVisibleTabs]-1))
	{
		NSUInteger dropDownIndex=selectedIndex-[self numberVisibleTabs];
		[[[dropDownMenu menu] itemAtIndex: dropDownIndex] setTitle: newTitle];
	}
}

-(void)selectTabAtIndex: (NSUInteger)index
{
	[((PKTab*)[tabs objectAtIndex: index]) selectTab];
}

-(void)closeTabAtIndex: (NSUInteger)index
{
	[((PKTab*)[tabs objectAtIndex: index]) closeTab];
}

-(NSUInteger)selectedTabIndex
{
	return [tabs indexOfObjectIdenticalTo: selectedTab];
}

-(NSUInteger)tabCount
{
	return [tabs count];
}

-(NSUInteger)numberVisibleTabs
{
	return [self tabCount]-[self numberHiddenTabs];
}

-(NSUInteger)numberHiddenTabs
{
	return numberHiddenTabs;
}

-(void)frameResized: (NSNotification*)notification
{
	//calculate a new hide index based on the new resize of the frame
	NSUInteger newHideIndex=(([self frame].size.width-26)/106)-1;
	//now we check to see if the new hide index was smaller than last time or larger
	if(newHideIndex<hideIndex && hideIndex<[self tabCount])
	{
		//we just covered up yet another tab, we are shrinking in size
		//move the newly covered up tab to the drop down
		[self moveTabWithIndexToDropDown: hideIndex];
	}
	else if(newHideIndex>hideIndex && newHideIndex<[self tabCount])
	{
		//we just fully unveiled a tab, we are increasing in size
		//move the previously hidden tab out of the drop down
		[self moveTabWithIndexFromDropDown: newHideIndex];
	}
	//set the new hide index to the current hide index
	hideIndex=newHideIndex;
}

-(void)moveTabWithIndexToDropDown: (NSUInteger)index
{
	numberHiddenTabs++;
	//hide the specified tab
	[[tabs objectAtIndex: index] setHidden: YES];
	//add the title of the newly hidden tab to the dropdown menu
	NSMenuItem* addedMenuItem=[[dropDownMenu menu] insertItemWithTitle: [((PKTab*)[tabs objectAtIndex: index]) title] action: @selector(tabWasSelectedFromMenu:) keyEquivalent: @"" atIndex: 0];
	[addedMenuItem setTarget: self];
	//test to see if we should have this newly added menu item selected
	if([self selectedTabIndex]==index)
	{
		//the tab we just hid was selected so that means we should have this menu item selected
		[addedMenuItem setState: NSOnState];
	}
	else
	{
		//the tab we just hid was not selected so that means we should not have this menu item selected
		[addedMenuItem setState: NSOffState];
	}
	[dropDownMenu setFrameOrigin: NSMakePoint(index*106, -2)];
	[dropDownMenu setHidden: NO];
}

-(void)moveTabWithIndexFromDropDown: (NSUInteger)index
{
	numberHiddenTabs--;
	//show the specified tab
	[[tabs objectAtIndex: index] setHidden: NO];
	//remove the newly revieled tab from the drop down menu
	[dropDownMenu removeItemAtIndex: 0];
	[dropDownMenu setFrameOrigin: NSMakePoint((index+1)*106, -2)];
	//test if we should hide drop down menu
	if([self numberHiddenTabs]<=0)
	{
		//we have no hidden tabs, hide the drop down menu
		[dropDownMenu setHidden: YES];
	}
}

-(void)tabWillBeSelected: (PKTab*)newlySelectedTab
{
	//a tab is about to selected
	//unselect the previous tab
	[selectedTab unselectTab];
	//check to see if we need to "unselect" the previous tab if it is in the dropdown menu
	NSInteger selectedDifferenceIndex=[self selectedTabIndex]-[self numberVisibleTabs];
	//if the index of the tab is positive, which means it would be in the menu, and if it is less than the highest possible index in the drop down menu
	if(selectedDifferenceIndex>=0 && ([[dropDownMenu menu] numberOfItems]-1)>=selectedDifferenceIndex)
	{
		//we need to "unselect" the previous tab
		[[[dropDownMenu menu] itemAtIndex: selectedDifferenceIndex] setState: NSOffState];
	}
	//release the previous tab and retain the new one if needed
	if(selectedTab!=newlySelectedTab)
	{
		[selectedTab release];
		selectedTab=[newlySelectedTab retain];
	}
	//test if we need to put a check mark by the newly selected tab if this tab was selected programatically
	//if the index of the tab is positive, which means it would be in the menu, and if it is less than the highest possible index in the drop down menu
	//I'm reusing the selectedDifferenceIndex variable
	selectedDifferenceIndex=[self selectedTabIndex]-[self numberVisibleTabs];
	if(selectedDifferenceIndex>=0 && ([[dropDownMenu menu] numberOfItems]-1)>=selectedDifferenceIndex)
	{
		//we need to "select" the newly selected tab
		[[[dropDownMenu menu] itemAtIndex: selectedDifferenceIndex] setState: NSOnState];
	}
	
	//now tell the delegate that the tab will change to one at an index
	if([delegate respondsToSelector: @selector(willSelectTabAtIndex:)])
	{
		[delegate performSelector: @selector(willSelectTabAtIndex:) withObject: [NSNumber numberWithUnsignedInteger: [tabs indexOfObjectIdenticalTo: newlySelectedTab]]];
	}
}

-(void)tabWasSelected: (PKTab*)newlySelectedTab
{
	//now tell the delegate that the tab changed to one at an index
	if([delegate respondsToSelector: @selector(didSelectTabAtIndex:)])
	{
		[delegate performSelector: @selector(didSelectTabAtIndex:) withObject: [NSNumber numberWithUnsignedInteger: [tabs indexOfObjectIdenticalTo: newlySelectedTab]]];
	}
}

-(void)tabWasSelectedFromMenu: (NSMenuItem*)selectedItem
{
	//set the state of the newly selected item to be on
	[selectedItem setState: NSOnState];
	//get the index of the selected menu item
	NSUInteger selectedMenuIndex=[dropDownMenu indexOfSelectedItem];
	//calculate the final index based on the number of visible tabs
	NSUInteger selectedTabIndex=selectedMenuIndex+[self numberVisibleTabs];
	//tell the tab at the final index to be selected
	[((PKTab*)[tabs objectAtIndex: selectedTabIndex]) selectTab];
}

-(void)willCloseTab: (PKTab*)dyingTab
{
	//a tab is about to close
	NSUInteger dyingTabIndex=[tabs indexOfObjectIdenticalTo: dyingTab];
	
	//tell the delegate that we will close a tab
	if([delegate respondsToSelector: @selector(willCloseTabAtIndex:)])
	{
		[delegate performSelector: @selector(willCloseTabAtIndex:) withObject: [NSNumber numberWithUnsignedInteger: dyingTabIndex]];
	}
	
	//check if the closing tab is the selected tab, the last tab, or any other tab
	if(selectedTab==dyingTab)
	{
		//we are closing the selected tab
		//decide what next tab to select, default to the same index (since that is the tab we want selected after we delete the tab)
		nextSelectTab=dyingTabIndex;
		if(dyingTabIndex==[self tabCount]-1)
		{
			//we are closing the last tab
			//select the second to last (soon to be last)
			nextSelectTab=dyingTabIndex-1;
		}
	}
	else if([self selectedTabIndex]==[self tabCount]-1)
	{
		nextSelectTab=[self selectedTabIndex]-1;
	}
	else
	{
		nextSelectTab=[self selectedTabIndex];
	}
	
	//iterate through the remaining tabs after this one and move them down
	NSUInteger currentTabIndex=dyingTabIndex+1;
	for(currentTabIndex=dyingTabIndex+1; currentTabIndex<[self tabCount]; currentTabIndex++)
	{
		PKTab* currentTab=[tabs objectAtIndex: currentTabIndex];
		[currentTab setFrameOrigin: NSMakePoint([currentTab frame].origin.x-[dyingTab frame].size.width, 0)];
	}
	
	//if the tab was in the dropdown menu, remove it from there as well
	if(dyingTabIndex>([self numberVisibleTabs]-1))
	{
		//the dying tab was in the dropdown menu
		NSUInteger dropDownIndex=dyingTabIndex-[self numberVisibleTabs];
		[dropDownMenu removeItemAtIndex: dropDownIndex];
		//since I removed an item from the dropdown menu, decrement the number of hidden tabs
		numberHiddenTabs--;
		//test if we should hide drop down menu
		if([self numberHiddenTabs]<=0)
		{
			//we have no hidden tabs, hide the drop down menu
			[dropDownMenu setHidden: YES];
		}
	}
	
	//lastly, remove the tab from the array we have set up
	[tabs removeObjectAtIndex: dyingTabIndex];
}

-(void)didCloseTab: (PKTab*)dyingTab
{
	//if it was not in the dropdown menu, pop one tab from the dropdown menu if needed
	if(![dyingTab isHidden] && [self numberHiddenTabs]>0)
	{
		//the dying tab was visable and not in the dropdown menu
		//the reason that the index we want to move from the dropdown is [self numberVisibleTabs] is because we want to move over the first dropdown menu tab.  That tab is the first index after the index of the last visable tab which is also equal to the count of the visable tabs.
		[self moveTabWithIndexFromDropDown: [self numberVisibleTabs]];
	}
	//now that the last tab has officially been removed, select the "next" tab
	[((PKTab*)[tabs objectAtIndex: nextSelectTab]) selectTab];
	//check to see if there is only one more tab now, and if so, hide its close button
	if([self tabCount]==1)
	{
		[((PKTab*)[tabs objectAtIndex: 0]) hideCloseButton: YES];
	}
}

-(void)drawRect: (NSRect)dirtyRect
{
	/*
	//test if we are live resizing (such as when we are resizing the window)
	if([self inLiveResize])
	{
		//test if we are too small to display all the tabs
		//if([self frame].size.width<[self tabCount]*106+26)
		{
			//we are too small to display all the tabs
			//add the dropdown menu
			NSUInteger newHideIndex=(([self frame].size.width-26)/106)-1;
			if(newHideIndex<hideIndex && hideIndex<[self tabCount])
			{
				//we just covered up yet another tab, we are shrinking in size
				//hide the newly covered up tab
				[[tabs objectAtIndex: hideIndex] setHidden: YES];
				hideIndex=newHideIndex;
			}
			else if(newHideIndex>hideIndex && hideIndex<[self tabCount])
			{
				//we just fully unveiled a tab, we are increasing in size
				//show the previously hidden tab
				[[tabs objectAtIndex: newHideIndex] setHidden: NO];
				hideIndex=newHideIndex;
			}
			
			//[dropDownMenu setFrameOrigin: NSMakePoint(([[self subviews] count]-1)*106, 0)];
			//[dropDownMenu setHidden: NO];
		}
		//else
		{
			//[dropDownMenu setHidden: YES];
		}
	}
	*/
}

-(void)dealloc
{
	[tabs release];
	[selectedTab release];
	[delegate release];
	[super dealloc];
}

@end
