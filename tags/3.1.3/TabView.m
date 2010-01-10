//
//  TabView.m
//  Man Viewer
//
//  Created by Peter Kendall on 3/30/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "TabView.h"


@implementation TabView

-(id)initWithFrame: (NSRect)frame
{
	self=[super initWithFrame: frame];
	if(self)
	{
		[self setManEntry:[[ManEntry alloc] init]];
		selectedImage=[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"tab_selected" ofType: @"png" inDirectory: @""]];
		notSelectedImage=[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"tab_unselected" ofType: @"png" inDirectory: @""]];
		hoverImage=[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"tab_hover" ofType: @"png" inDirectory: @""]];
		//set up the textbox
		text=[[NSTextField alloc] initWithFrame: NSMakeRect(1, 8, 100, 17)];
		[text setEditable: NO];
		[text setSelectable: NO];
		[text setDrawsBackground: NO];
		[text setBordered: NO];
		[text setStringValue: @"Select a man page"];
		[self addSubview: text];
		//set up the button
		close=[[NSButton alloc] initWithFrame: NSMakeRect(110, 1, 30, 30)];
		[close setBezelStyle: NSCircularBezelStyle];
		[close setBordered: YES];
		[close setTitle: @"X"];
		[close setTarget: self];
		[close setAction: @selector(closeSelf:)];
		[self addSubview: close];
		//set up the hover functionality
		tracker=[[NSTrackingArea alloc] initWithRect: NSMakeRect(0, 0, 150, 34) options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil];
		[self addTrackingArea: tracker];
		//we are selected!
		[self setSelected: YES];
		hovered=NO;
		//default to not in the drop down
		inDropDown=NO;
	}
	return self;
}

-(void)drawRect: (NSRect)rect
{
	if([self selected])
	{
		[selectedImage drawInRect: rect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
	}
	else if(hovered)
	{
		[hoverImage drawInRect: rect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
	}
	else
	{
		[notSelectedImage drawInRect: rect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
	}
	[text setNeedsDisplay: YES];
	[close setNeedsDisplay: YES];
}

-(BOOL)selected
{
	return selected;
}

-(void)setSelected: (BOOL)select
{
	selected=select;
}

-(void)closeSelf: (id)sender
{
	[/*(TabCollectionView*)*/[self superview] tabToBeRemoved: self];
}
-(void)mouseEntered: (NSEvent*)theEvent
{
	hovered=YES;
	[self setNeedsDisplay: YES];
}

-(void)mouseExited: (NSEvent*)theEvent
{
	hovered=NO;
	[self setNeedsDisplay: YES];
}

-(void)mouseDown: (NSEvent*)theEvent
{
	[/*(TabCollectionView*)*/[self superview] setCurrentTab: self];
	hovered=NO;
	//[self setSelected: YES];
	[self setNeedsDisplay: YES];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"atPAKTabChange" object: self];
}

-(ManEntry*)manEntry
{
	return manEntry;
}

-(void)setManEntry: (ManEntry*) newValue
{
	[manEntry autorelease];
	manEntry=[newValue retain];
	[text setStringValue: [NSString stringWithFormat: @"%@ (%@)", [[self manEntry] name], [[self manEntry] section]]];
	[self setNeedsDisplay: YES];
}

-(void)closeEnabled: (BOOL)flag
{
	[close setEnabled: flag];
}

-(void)dealloc
{
	[manEntry release];
	[selectedImage release];
	[notSelectedImage release];
	[hoverImage release];
	[text release];
	[close release];
	[tracker release];
	[super dealloc];
}

@end
