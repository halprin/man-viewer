//
//  TabDropdownView.m
//  Man Viewer
//
//  Created by Peter Kendall on 5/26/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "TabDropdownView.h"


@implementation TabDropdownView

-(id)initWithFrame: (NSRect)frame
{
	self=[super initWithFrame: frame];
	if(self)
	{
		dropDown=[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"tab_dropdown" ofType: @"png" inDirectory: @""]];
		[dropDown setFlipped: YES];
		tabs=[[NSMutableArray array] retain];
		//auto enable items added to the dropdown
		[self setAutoenablesItems: NO];
	}
	return self;
}

-(void)drawRect: (NSRect)rect
{
	[dropDown drawInRect: rect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
}

-(void)push: (TabView*)tab
{
	[tabs addObject: tab];
	[[[self menu] addItemWithTitle: [[[tab manEntry] name] stringByAppendingFormat: @" (%@)", [[tab manEntry] section]] action: @selector(itemSelected:) keyEquivalent: @""] setTarget: self];
	//[[[self menu] itemAtIndex: ([[self menu] numberOfItems]-1)] setEnabled: YES];
	//[[[self menu] itemAtIndex: 0] setEnabled: YES];
}

-(void)itemSelected: (NSMenuItem*)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"atPAKTabChange" object: [tabs objectAtIndex: [[self menu] indexOfItem: sender]]];
}

-(TabView*)pop;
{
	TabView* tab=[tabs objectAtIndex: [tabs count]-1];
	[[self menu] removeItemAtIndex: [tabs count]-1];
	[tabs removeLastObject];
	return tab;
}

-(BOOL)hasItems
{
	return ([tabs count]>0);
}

-(void)dealloc
{
	[dropDown release];
	[tabs release];
	[super dealloc];
}

@end
