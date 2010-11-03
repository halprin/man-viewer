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
	if([newOne count]>=1)
	{
		[subtractButton setEnabled: YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: NSControlTextDidChangeNotification object: adder];
}

-(IBAction)delete:(id)sender
{
	[newOne removeObjectAtIndex: [entries selectedRow]];
	[entries reloadData];
	if([newOne count]<1)
	{
		[subtractButton setEnabled: NO];
	}
}

-(IBAction)ok:(id)sender
{
	[entries deselectRow: [entries editedRow]];
	[*original autorelease];
	*original=[[NSMutableArray arrayWithArray: newOne] retain];
	[window orderOut: self];
	[NSApp endSheet: window returnCode: 0];
}

-(IBAction)setToManpath: (id)sender
{
	//stop any editing that was happening
	[entries deselectRow: [entries editedRow]];
	//because GUI applications do not branch off of bash (or any shell), certain environment variables do not exist for GUI applications (such as $MANPATH or a custom $PATH)
	//so we need to actually rerun the login shell as if it is the login CLI so it rereads all it's configuration files and recreates the $MANPATH variable and $PATHs
	//So what this task is calling a helper program that I created that all it does is exec's the passed in shell with "-" as argv[0] (so it thinks it is a login shell), "-i" so it thinks it is interactive, and finally "-c /usr/bin/manpath" so it executes that command once the shell is done loading.
	NSTask* task=[[NSTask alloc] init];
	[task setLaunchPath: [[[NSBundle mainBundle] bundlePath] stringByAppendingString: @"/Contents/Resources/manpath_helper"]];
	//set the arguments and the output pipe
	[task setArguments: [NSArray arrayWithObjects: [[[NSProcessInfo processInfo] environment] valueForKey: @"SHELL"], nil]];
	[task setStandardInput: [NSPipe pipe]];
	[task setStandardOutput: [NSPipe pipe]];
	NSFileHandle* output=[[task standardOutput] fileHandleForReading];
	//fire!
	[task launch];
	[task waitUntilExit];
	[task release];
	//get the entire response
	NSString* man_path=[[[NSString alloc] initWithData: [output readDataToEndOfFile] encoding: NSUTF8StringEncoding] autorelease];
	//stick the response into the list
	[newOne autorelease];
	//break it up by \n
	NSArray* return_temp=[man_path componentsSeparatedByString: @"\n"];
	//get basically the last full line because it will always be the manpath command output because logout output by the shell is not returned
	newOne=[[[return_temp objectAtIndex: [return_temp count]-2] componentsSeparatedByString: @":"] retain];
	//update the list
	[entries reloadData];
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
	[entries deselectRow: [entries editedRow]];
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
