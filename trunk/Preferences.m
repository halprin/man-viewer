//
//  Preferences.m
//  Man Viewer
//
//  Created by Peter Kendall on 1/31/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "Preferences.h"


@implementation Preferences

-(Preferences*)init
{
	if(self=[super init])
	{
		//get notifications when the add textbox has changed
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textChange:) name: @"NSControlTextDidChangeNotification" object: adder];
	}
	return self;
}

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
	[adder setStringValue: @""];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"NSControlTextDidChangeNotification" object: adder];
}

-(IBAction)delete:(id)sender
{
	[newOne removeObjectAtIndex: [entries selectedRow]];
	[entries reloadData];
}

-(IBAction)ok:(id)sender
{
	[*original autorelease];
	*original=[[NSMutableArray arrayWithArray: newOne] retain];
	[window orderOut: self];
	[NSApp endSheet: window returnCode: 0];
}

-(void)textChange: (NSNotification*)notification
{
	if([[adder stringValue] length]!=0)  //the adder textbox has text so enable the add button
	{
		[addButton setEnabled: YES];
	}
	else  //disable the add button
	{
		[addButton setEnabled: NO];
	}
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
