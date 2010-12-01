//
//  PKTab.m
//  Man Viewer
//
//  Created by Peter Kendall on 11/3/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "PKTab.h"
#import "PKTabCell.h"


@implementation PKTab

-(PKTab*)initWithFrame: (NSRect)frameRect
{
	//before we initialize, set our class' cell to the PKTabCell
	[PKTab setCellClass: [PKTabCell class]];
	if(self=[super initWithFrame: frameRect])
	{
		//set up all the attributes needed
		[self setBezelStyle: NSSmallSquareBezelStyle];
		[self setAlignment: NSLeftTextAlignment];
		[self setTitle: @""];
		[[self cell] setShowsStateBy: NSChangeGrayCellMask];
		[self setTarget: self];
		[self setAction: @selector(selectTab)];
		
		//alloc and set up the attributes for the close button
		closeButton=[[NSButton alloc] initWithFrame: NSMakeRect(3, 3, 15, 16)];
		[closeButton setImage: [NSImage imageNamed: @"NSStopProgressFreestandingTemplate"]];
		[[closeButton cell] setImageScaling: NSImageScaleProportionallyDown];
		[closeButton setBordered: NO];
		[closeButton setTarget: self];
		[closeButton setAction: @selector(closeTab)];
		[closeButton setHidden: YES];
		[self addSubview: closeButton];
		
		//set up the hover functionality
		tracker=[[NSTrackingArea alloc] initWithRect: [self bounds] options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect) owner: self userInfo: nil];
		[self addTrackingArea: tracker];
		
		//other stuff
		selected=NO;
		forceHideCloseButton=NO;
		cursorInside=NO;
		delegate=nil;
	}
	
	return self;
}

-(void)setDelegate: (id)newDelegate
{
	if(delegate!=newDelegate)
	{
		//this is not the same object
		[delegate release];
		delegate=[newDelegate retain];
	}
}

-(void)selectTab;
{
	//tell the delegate that we will be selecting ourselves
	if([delegate respondsToSelector: @selector(tabWillBeSelected:)])
	{
		[delegate performSelector: @selector(tabWillBeSelected:) withObject: self];
	}
	
	//set our internal flag to specify that we are selected
	selected=YES;
	//change our shading to show selectedness
	[self setState: NSOnState];
	
	//tell the delegate that we did select ourselves
	if([delegate respondsToSelector: @selector(tabWasSelected:)])
	{
		[delegate performSelector: @selector(tabWasSelected:) withObject: self];
	}
}

-(void)unselectTab
{
	//set our internal flag to specify that we are not selected
	selected=NO;
	//change our shading to show unselectedness
	[self setState: NSOffState];
}

-(void)closeTab
{
	//tell the delegate that we will be closing ourselves by removing ourselves from the superview
	if([delegate respondsToSelector: @selector(willCloseTab:)])
	{
		[delegate performSelector: @selector(willCloseTab:) withObject: self];
	}
	
	//remove ourselves from the superview
	[self removeFromSuperview];
	
	//tell the delegate that we did close ourselves by removing ourselves from the superview
	if([delegate respondsToSelector: @selector(didCloseTab:)])
	{
		[delegate performSelector: @selector(didCloseTab:) withObject: self];
	}
}

-(void)hideCloseButton: (BOOL)flag
{
	forceHideCloseButton=flag;
	//check to see if the cursor is already inside the tab
	if(cursorInside)
	{
		//the cursor is already inside the tab's bounds, that means we need to update here and now on the fly
		[closeButton setHidden: flag];
	}
}

-(void)mouseEntered: (NSEvent*)theEvent
{
	cursorInside=YES;
	//the mouse entered into the tab, display the close button possibly
	if(!forceHideCloseButton)
	{
		[closeButton setHidden: NO];
	}
}

-(void)mouseExited: (NSEvent*)theEvent
{
	cursorInside=NO;
	//the mouse left the tab, hide the close button
	[closeButton setHidden: YES];
}

-(void)dealloc
{
	[tracker release];
	[closeButton release];
	[delegate release];
	[super dealloc];
}

@end
