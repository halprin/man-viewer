//
//  Preferences.m
//  Man Viewer
//
//  Created by Peter Kendall on 1/31/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "Preferences.h"


@implementation Preferences

-(int)numberOfRowsInTableView: (NSTableView*)aTableView
{
	return [newOne count];
}

-(id)tableView: (NSTableView*)aTableView objectValueForTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex
{
	NSParameterAssert(rowIndex>=0 && rowIndex<[newOne count]);
	id theValue=[newOne objectAtIndex: rowIndex];
	return theValue;
}

-(void)tableView: (NSTableView*)aTableView setObjectValue: (id)anObject forTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex
{
	NSParameterAssert(rowIndex>=0 && rowIndex<[newOne count]);
	[newOne replaceObjectAtIndex: rowIndex withObject: anObject];
}

-(void)addEntry: (NSString*)name withReload: (BOOL)flag
{
	[newOne addObject: name];
	if(flag)
	{
		[entries reloadData];
	}
}

-(IBAction)add:(id)sender
{
	[self addEntry: [adder stringValue] withReload: YES];
}

-(IBAction)delete:(id)sender
{
	
}

-(IBAction)ok:(id)sender
{
	[*original autorelease];
	*original=[[NSMutableArray arrayWithArray: newOne] retain];
	[window orderOut: self];
	[NSApp endSheet: window returnCode: 0];
}

-(IBAction)cancel:(id)sender
{
	[window orderOut: self];
	[NSApp endSheet: window returnCode: 0];
}

-(NSWindow*)window
{
	return window;
}

-(void)setOriginal: (NSMutableArray**)theOriginal;
{
	original=theOriginal;
}

-(void)loadOriginal
{
	[newOne autorelease];
	newOne=[[NSMutableArray arrayWithArray: *original] retain];
	[entries reloadData];
}

-(void)dealloc
{
	[newOne release];
	[super dealloc];
}

@end
