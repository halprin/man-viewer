#import "ViewerManager.h"

@implementation ViewerManager

-(ViewerManager*)init
{
	if(self=[super init])
	{
		searchDirectories=[NSMutableArray array];
		[searchDirectories retain];
		searchString=[[NSString string] retain];
		filterString=[[NSString string] retain];
		loaded=NO;
	}
	return self;
}

-(void)tableViewSelectionDidChange: (NSNotification*)notification
{
	//if the man pages haven't been loaded yet, bail out
	if(!loaded)
	{
		return;
	}
	//this comes up when doing the searching
	//it needs to bail out or it exploes
	if([[manlist selectedObjects] count]<1)
	{
		return;
	}
	ManEntry* entry=[[manlist selectedObjects] objectAtIndex: 0];
	NSString* man=[entry name];
	NSString* section=[entry section];
	//concat the searchDirectories together
	NSString* directories=[NSString string];
	for(NSString* directory in searchDirectories)
	{
		directories=[[directories stringByAppendingString: directory] stringByAppendingString: @":"];
	}
	directories=[directories substringToIndex: [directories length]-1];
	
	NSTask* task=[[NSTask alloc] init];
	[task autorelease];
	[task setLaunchPath: @"/usr/bin/man"];
	//set the arguments and the output pipe
	[task setArguments: [NSArray arrayWithObjects: section, man, @"-M", directories, nil]];
	[task setStandardOutput: [NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	NSFileHandle *file=[[task standardOutput] fileHandleForReading];
	NSFileHandle *error=[[task standardError] fileHandleForReading];
	[task launch];
	//get the output
	NSData* encodedMan=[NSData dataWithData: [file readDataToEndOfFile]];
	//check if we had an error
	if([[error readDataToEndOfFile] length]>0)
	{
		//we had an error, most likely that man page does not exist
		[[[viewer textStorage] mutableString] setString: @"That man page does not exist!"];
		return;
	}
	
	
	task=[[NSTask alloc] init];
	[task autorelease];
	[task setLaunchPath: @"/usr/bin/col"];
	//set the arguments and the output pipe
	[task setArguments: [NSArray arrayWithObjects: @"-b", nil]];
	[task setStandardInput: [NSPipe pipe]];
	[task setStandardOutput: [NSPipe pipe]];
	NSFileHandle* input=[[task standardInput] fileHandleForWriting];
	file=[[task standardOutput] fileHandleForReading];
	[task launch];
	[input writeData: encodedMan];
	[input closeFile];

	NSString *contents=[[NSString alloc] initWithData: [file readDataToEndOfFile] encoding: NSUTF8StringEncoding];
	[contents autorelease];
	
	//actually display the stuff
	if(contents==nil)
	{
		[[[viewer textStorage] mutableString] setString: @"That man page does not exist!"];
	}
	else
	{
		[[[viewer textStorage] mutableString] setString: contents];
	}
}

-(void)addEntry: (NSString*)name withSection: (NSString*)section
{
	ManEntry* newOne=[[[ManEntry alloc] initWithName: name andSection: section] autorelease];
	NSUInteger location=[[manlist content] indexOfObject: newOne];
	if(location!=NSNotFound)
	{
		[[manlist content] removeObjectAtIndex: location];
	}
	[manlist addObject: newOne];
}

-(void)applicationDidFinishLaunching: (NSNotification*)notification
{
	//set the font
	[[viewer textStorage] setFont: [NSFont fontWithName: @"Courier" size: 12.0]];
	//set the predicate
	
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
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
	loaded=YES;
}

-(void)applicationWillTerminate: (NSNotification*)notification
{
	//write the preferences
	NSMutableDictionary *root=[NSMutableDictionary dictionary];
	[root setValue: searchDirectories forKey: @"searchDirectories"];
	[root writeToFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"] atomically: YES];
}

-(IBAction)showPreferences: (id)sender
{
	[preferences setOriginal: &searchDirectories];
	[NSApp beginSheet: [preferences window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
}

-(IBAction)search: (id)sender
{
	//set the searchString
	[searchString autorelease];
	searchString=[[NSString stringWithString: [sender stringValue]] retain];
	
	if(![filterString isEqualToString: @""] && ![searchString isEqualToString: @""])
	{
		//both are set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"section BEGINSWITH %@ && name CONTAINS %@", filterString, searchString]];
	}
	else if(![searchString isEqualToString: @""])
	{
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"name CONTAINS %@", searchString]];
	}
	else if(![filterString isEqualToString: @""])
	{
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"section BEGINSWITH %@", filterString]];
	}
	else
	{
		[manlist setFilterPredicate: nil];
	}
}

-(IBAction)filter: (id)sender
{
	//TODO:  implement the filtering
	NSLog(@"section=%i", [sender indexOfSelectedItem]);
}

-(IBAction)update: (id)sender
{
	loaded=NO;
	//show the loader sheet
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	[self load];
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
	loaded=YES;
}

-(void)load
{
	//clear the list
	[[manlist content] removeAllObjects];
	//set up the progress bar
	[[loader progressBar] setDoubleValue: 0.0];
	[[loader progressBar] setMaxValue: 10*[searchDirectories count]];
	[window display];
	[[loader window] display];
	
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
					//test if there is .gz extentsion and remove it
					if([[man pathExtension] isEqualToString: @"gz"])
					{
						man=[man stringByReplacingOccurrencesOfString: @".gz" withString: @""];
					}
					//parse out the section and format
					NSString* section=[[man componentsSeparatedByString: @"."] lastObject];
					man=[man substringToIndex: ([man length]-[section length]-1)];
					[self addEntry: man withSection: section];
				}
			}
			//update the progress bar
			[[loader progressBar] incrementBy: 1.0];
			[[loader window] display];
		}
	}
	//update the progress bar
	[[loader progressBar] setDoubleValue: [[loader progressBar] maxValue]];
	[[loader window] display];
	
	//set the sort type
	NSSortDescriptor* sorter=[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];
	[sorter autorelease];
	[manlist setSortDescriptors: [NSArray arrayWithObject: sorter]];
	
	[manlist rearrangeObjects];
}

-(void)dealloc
{
	[searchDirectories release];
	[searchString release];
	[filterString release];
	[super dealloc];
}

@end

//TODO:  Add HTML credit section to appear in About Man Viewer menu item
