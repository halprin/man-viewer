//
//  PAKTableView.m
//  Man Viewer
//
//  Created by Peter Kendall on 1/9/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "PAKTableView.h"


@implementation PAKTableView

-(NSMenu*)menuForEvent: (NSEvent*)event
{
	if([event type]==NSRightMouseDown || ([event type]==NSLeftMouseDown && ([event modifierFlags] & NSControlKeyMask)))
	{
		//get the current selections for the outline view. 
		NSIndexSet* selectedRowIndexes=[self selectedRowIndexes];
		
		//select the row that was clicked before showing the menu for the event
		NSPoint mousePoint = [self convertPoint: [event locationInWindow] fromView: nil];
		NSInteger row=[self rowAtPoint: mousePoint];
		
		//figure out if the row that was just clicked on is currently selected
		if([selectedRowIndexes containsIndex: row]==NO)
		{
			[self selectRow: row byExtendingSelection: NO];
		}
		//else that row is currently selected, so don't change anything.
		
		NSMenu* finder_reveal=[[[NSMenu alloc] initWithTitle: @"Reveal Context"] autorelease];
		[finder_reveal addItemWithTitle: @"Reveal in Finder" action: @selector(revealInFinder:) keyEquivalent: @""];
		return finder_reveal;
	}
	
	return [super menuForEvent: event];
}

@end
