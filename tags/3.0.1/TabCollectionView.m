//
//  TabCollectionView.m
//  Man Viewer
//
//  Created by Peter Kendall on 3/30/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "TabCollectionView.h"


@implementation TabCollectionView

-(id)initWithFrame: (NSRect)frame
{
    self=[super initWithFrame: frame];
    if(self)
	{
		//add the first tab
		[self addSubview: [[TabView alloc] initWithFrame: NSMakeRect(0, 0, 150, 34)]];
		//make it the first tab
		[self setCurrentTab: [[self subviews] objectAtIndex: 0]];
		//since it is the only tab to begin with, disable the close button
		[[[self subviews] objectAtIndex: 0] closeEnabled: NO];
    }
    return self;
}

-(void)drawRect: (NSRect)rect
{
	//count how many tabs are actually displayable
	displayable=[self bounds].size.width/150.0;
	
	//display the dropdown if needed
	if(displayable<[[self subviews] count] || [dropdown hasItems])
	{
		[dropdown setHidden: NO];
	}
	else
	{
		[dropdown setHidden: YES];
	}
	
	if(displayable-((int)[[self subviews] count])<0)
	{
		//move to the dropdown
		int lcv;
		int range=[[self subviews] count];
		//iterate through the ones needing to be moved
		TabView* tab;
		for(lcv=displayable; lcv<range; lcv++)
		{
			//remove them from the main tab view and to the dropdown
			tab=[[self subviews] objectAtIndex: lcv];
			[tab removeFromSuperview];
			[dropdown push: tab];
		}
	}
	else if(displayable-[[self subviews] count]>0 && [dropdown hasItems])
	{
		//move back to the main tab view
		[self addSubview: [dropdown pop]];
	}
}

-(IBAction)addTab: (id)sender
{
	//add a new tab that will automaticly be selected
	[self addSubview: [[TabView alloc] initWithFrame: NSMakeRect([[self subviews] count]*150, 0, 150, 34)]];
	[self setCurrentTab: [[self subviews] objectAtIndex: [[self subviews] count]-1]];
	//if we have tabs to spare (more than 1)
	if([[self subviews] count]==2)
	{
		//enable the close of the first one
		[[[self subviews] objectAtIndex: 0] closeEnabled: YES];
	}
}

-(IBAction)nextTab: (id)sender
{
	int index=[[self subviews] indexOfObject: [self currentTab]];
	index++;
	if(index==[[self subviews] count])
	{
		index=0;
	}
	[self setCurrentTab: [[self subviews] objectAtIndex: index]];
}

-(IBAction)previousTab: (id)sender
{
	int index=[[self subviews] indexOfObject: [self currentTab]];
	index--;
	if(index==-1)
	{
		index=[[self subviews] count]-1;
	}
	[self setCurrentTab: [[self subviews] objectAtIndex: index]];
}

-(void)tabToBeRemoved: (TabView*)sender
{
	//is the tab to be removed currently selected?
	BOOL selected=[sender selected];
	//remove the tab
	[sender removeFromSuperview];
	//test if it was selected
	if(selected)
	{
		//change the current sellected tab
		[self setCurrentTab: [[self subviews] objectAtIndex: [[self subviews] count]-1]];
	}
	//shuffle all the tabs down to the left side
	int lcv=0;
	for(TabView* tab in [self subviews])
	{
		[tab setFrame: NSMakeRect(lcv*150, 0, 150, 34)];
		lcv++;
	}
	//test to see if there is only 1 tab left
	if([[self subviews] count]==1)
	{
		//disable the close button
		[[[self subviews] objectAtIndex: 0] closeEnabled: NO];
	}
	[self setNeedsDisplay: YES];
}

-(TabView*)currentTab
{
	return currentTab;
}

-(void)setCurrentTab: (TabView*)newValue
{
	[currentTab autorelease];
	currentTab=[newValue retain];
	//iterate through all tabs and make all of them not selected
	for(TabView* tab in [self subviews])
	{
		[tab setSelected: NO];
	}
	//make the current tab the selected one
	[newValue setSelected: YES];
	//repaint
	[self setNeedsDisplay: YES];
	//notify the main controller that we will probably need to display some new text
	[[NSNotificationCenter defaultCenter] postNotificationName: @"atPAKTabChange" object: currentTab];
}

-(void)dealloc
{
	[currentTab release];
	[super dealloc];
}

@end
