#import "ViewerManager.h"

@implementation ViewerManager

-(ViewerManager*)init
{
	if(self=[super init])
	{
		manlist=[NSMutableArray array];
		searchDirectories=[NSMutableArray array];
		[manlist retain];
		[searchDirectories retain];
	}
	return self;
}

-(int)numberOfRowsInTableView: (NSTableView*)aTableView
{
	return [manlist count];
}

-(id)tableView: (NSTableView*)aTableView objectValueForTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex
{
	NSParameterAssert(rowIndex>=0 && rowIndex<[manlist count]);
	id theRecord=[manlist objectAtIndex: rowIndex];
	id theValue=[theRecord objectForKey: [aTableColumn identifier]];
	return theValue;
}

-(void)tableView: (NSTableView*)aTableView setObjectValue: (id)anObject forTableColumn: (NSTableColumn*)aTableColumn row: (int)rowIndex
{
	NSParameterAssert(rowIndex>=0 && rowIndex<[manlist count]);
	id theRecord=[manlist objectAtIndex: rowIndex];
	[theRecord setObject: anObject forKey: [aTableColumn identifier]];
}

-(void)addEntry: (NSString*)name withReload: (BOOL)flag
{
	NSMutableDictionary *dict=[NSMutableDictionary dictionary];
	[dict setObject: name forKey: @"man"];
	[manlist addObject: dict];
	if(flag)
	{
		[entries reloadData];
	}
}

-(void)applicationDidFinishLaunching: (NSNotification*)notification
{
	[entries setDataSource: self];
	
	//load the preferences
	NSFileManager *prefs=[NSFileManager defaultManager];
	[searchDirectories autorelease];
	if([prefs fileExistsAtPath: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"]]==YES)  //The new prefs exist
	{
		NSDictionary *root=[NSDictionary dictionaryWithContentsOfFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"]];
		searchDirectories=[[root valueForKey: @"searchDirectories"] retain];
	}
	else
	{
		searchDirectories=[[NSArray arrayWithObjects: @"/usr/share/man/", @"/usr/local/share/man/", @"/usr/X11R6/man/", @"/usr/local/man/", nil] retain];
	}
	
	//show the loader sheet
	[[loader progressBar] setUsesThreadedAnimation: YES];
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	//now do the heavy lifting to read in the man pages
	[self load];
	[entries reloadData];
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
}

-(void)applicationWillTerminate: (NSNotification*)notification
{
	NSMutableDictionary *root=[NSMutableDictionary dictionary];
	[root setValue: searchDirectories forKey: @"searchDirectories"];
	[root writeToFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"] atomically: YES];
}

-(IBAction)showPreferences: (id)sender
{
	[preferences setOriginal: &searchDirectories];
	[preferences loadOriginal];
	[NSApp beginSheet: [preferences window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
}

-(IBAction)update: (id)sender
{
	//show the loader sheet
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	[self load];
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
}

-(void)load
{
	//clear the list
	[manlist removeAllObjects];
	
	//iterate through the search directories
	for(NSString* directory in searchDirectories)
	{
		int section;
		for(section=1; section<11; section++)  //for each man section (ex. man*)
		{
			//go through each potential sub man section directory
			NSString* addon;
			if(section==1)
			{
				addon=@"man1/";
			}
			else if(section==2)
			{
				addon=@"man2/";
			}
			else if(section==3)
			{
				addon=@"man3/";
			}
			else if(section==4)
			{
				addon=@"man4/";
			}
			else if(section==5)
			{
				addon=@"man5/";
			}
			else if(section==6)
			{
				addon=@"man6/";
			}
			else if(section==7)
			{
				addon=@"man7/";
			}
			else if(section==8)
			{
				addon=@"man8/";
			}
			else if(section==9)
			{
				addon=@"man9/";
			}
			else if(section==10)
			{
				addon=@"mann/";
			}
			NSString* path=[directory stringByAppendingString: addon];
			NSFileManager *checker=[NSFileManager defaultManager];  //used to see if sub directories exist and see the contents of them
			if([checker fileExistsAtPath: path])
			{
				//get the contents
				NSArray* contents=[checker contentsOfDirectoryAtPath: path error: NULL];
				for(NSString* man in contents)  //iterate through the contents and add them
				{
					[self addEntry: man withReload: NO];
				}
			}
		}
	}
	
	//sort
	//TODO:  fix sort so that lower and uppercase a/A's are together
	NSSortDescriptor* sorter=[[NSSortDescriptor alloc] initWithKey: @"man" ascending: YES];
	[sorter autorelease];
	[manlist sortUsingDescriptors: [NSArray arrayWithObject: sorter]];
}

-(void)dealloc
{
	[manlist release];
	[searchDirectories release];
	[super dealloc];
}

@end
