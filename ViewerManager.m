#import "ViewerManager.h"

@implementation ViewerManager

-(ViewerManager*)init
{
	if(self=[super init])
	{
		searchDirectories=[[NSMutableArray array] retain];
		searchString=[[NSString string] retain];
		filterString=[[NSString string] retain];
		cache=[[NSMutableArray array] retain];
		loaded=NO;
		//listen for changing tabs
		//[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(changeTab:) name: @"atPAKTabChange" object: nil];
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
		[[[viewer textStorage] mutableString] setString: @"Please select a man page from the list on the left."];
		return;
	}
	//scroll to the top so that once every new manpage is selected, it starts at the top
	[viewer scrollRangeToVisible: NSMakeRange(0, 0)];
	
	ManEntry* entry=[[manlist selectedObjects] objectAtIndex: 0];
	NSString* man=[entry path];
	
	//tell the current tab it's new man page
	//[tabs replaceObjectAtIndex: currentTab withObject: entry];
	//[[tabs currentTab] setManEntry: entry];
	//[[UITabs itemAtIndex: currentTab] setTitle: [man stringByAppendingFormat: @" (%@)", section]];
	
	NSTask* task=[[NSTask alloc] init];
	[task autorelease];
	[task setLaunchPath: @"/usr/bin/man"];
	//set the arguments and the output pipe
	[task setArguments: [NSArray arrayWithObjects: man, nil]];
	[task setStandardOutput: [NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	NSFileHandle* file=[[task standardOutput] fileHandleForReading];
	NSFileHandle* error=[[task standardError] fileHandleForReading];
	[task launch];
	//get the output
	//This parsing/splitting of the data is because of some of the man pages are so large, they choke up col.  We split it up in 131,072 byte sets.  Most man pages should fit in just one of these sets.
	NSMutableArray* encodedMan=[NSMutableArray array];
	NSData* data=[file readDataToEndOfFile];
	int dataOffset;
	int end=131072;
	if([data length]<end)
	{
		end=[data length];
	}
	for(dataOffset=0; dataOffset<[data length]; dataOffset+=131072)
	{
		if(dataOffset+end>[data length])
		{
			end=[data length]-dataOffset;
		}
		NSRange range={dataOffset, end};
		[encodedMan addObject: [data subdataWithRange: range]];
	}
	//check if we had an error
	if([[error readDataToEndOfFile] length]>0 && !([data length]>0))
	{
		//we had an error, most likely that man page does not exist
		[[[viewer textStorage] mutableString] setString: @"That man page does not exist!"];
		return;
	}
	
	//call /usr/bin/col for each 131,072 bytes of data because for any larger data, col crashes.
	NSMutableArray* contents=[NSMutableArray array];
	for(NSData* writeData in encodedMan)
	{
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
		[input writeData: writeData];
		[input closeFile];
		[contents addObject: [[[NSString alloc] initWithData: [file readDataToEndOfFile] encoding: NSUTF8StringEncoding] autorelease]];
	}
	
	//actually display the stuff
	if(contents==nil)
	{
		[[[viewer textStorage] mutableString] setString: @"That man page does not exist!"];
	}
	else
	{
		[[[viewer textStorage] mutableString] setString: [contents componentsJoinedByString: @""]];
	}
}

-(void)addEntry: (NSString*)name withSection: (NSString*)section andPath: (NSString*)path
{
	//this method assumes that no duplicates will be handed to it
	ManEntry* newOne=[[[ManEntry alloc] initWithName: name andSection: section andPath: path] autorelease];
	[manlist addObject: newOne];
}

-(void)applicationDidFinishLaunching: (NSNotification*)notification
{
	//set the font
	[[viewer textStorage] setFont: [NSFont fontWithName: @"Courier" size: 12.0]];
	//set the predicate
	
	//load the preferences
	NSFileManager *prefs=[NSFileManager defaultManager];
	NSString* preferencesVersion=nil;
	[searchDirectories autorelease];
	[cache autorelease];
	if([prefs fileExistsAtPath: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"]]==YES)  //The new prefs exist
	{
		//preferences do exist!
		//load the search directories
		NSDictionary *root=[NSDictionary dictionaryWithContentsOfFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"]];
		searchDirectories=[[root valueForKey: @"searchDirectories"] retain];
		cache=[[NSMutableArray arrayWithArray: [root valueForKey: @"cache"]] retain];
		preferencesVersion=[root valueForKey: @"preferencesVersion"];
	}
	else
	{
		//because GUI applications do not branch off of bash, so certain environment variables do not exist for GUI applications (such as $MANPATH)
		//so we need to actually rerun bash as if it is the login CLI so it rereads all it's configuration files and recreates the $MANPATH variable
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
		//break it up by \n
		NSArray* return_temp=[man_path componentsSeparatedByString: @"\n"];
		//get basically the last full line because it will always be the manpath command output because logout output by the shell is not returned
		//stick the response into the searchDirectories preference
		searchDirectories=[[[return_temp objectAtIndex: [return_temp count]-2] componentsSeparatedByString: @":"] retain];
		
		cache=[[NSMutableArray array] retain];
	}
	
	//show the loader sheet
	[[loader progressBar] setUsesThreadedAnimation: YES];
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	//do we want to force a load from the disk?
	CGEventRef event=CGEventCreate(NULL);
	CGEventFlags mods=CGEventGetFlags(event);
	
	//test if a cache exists
	NSString* version=[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
	if(cache!=nil && [cache count]>0 && !(mods & kCGEventFlagMaskCommand) && preferencesVersion!=nil && [preferencesVersion isEqualToString: version])
	{
		//the cache exists, has at least one item, or was not forced to load from disk; so load from cache
		[self loadFromCache];
	}
	else
	{
		//load from disk
		[cache autorelease];
		cache=[[NSMutableArray array] retain];
		//now do the heavy lifting to read in the man pages
		[self loadFromDisk];
	}
	
	//destroy the event that tests if the command key was pressed
	CFRelease(event);
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
	loaded=YES;
	
	//test if any command arguments were passed to this Cocoa application
	//supposed to be a name of a man page that is automatically selected
	if([[[NSProcessInfo processInfo] arguments] count]==2)
	{
		NSLog(@"Auto lookup %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1]);
		[manlist setSelectedObjects: [NSArray arrayWithObject: [[[ManEntry alloc] initWithName: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1] andSection: @"" andPath: @""] autorelease]]];
		//it is possible that multiple items were selected, make this just 1
		[manlist setSelectionIndex: [manlist selectionIndex]];
	}
	else if([[[NSProcessInfo processInfo] arguments] count]==3)
	{
		NSLog(@"Auto lookup %@ (%@)", [[[NSProcessInfo processInfo] arguments] objectAtIndex: 2], [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1]);
		[manlist setSelectedObjects: [NSArray arrayWithObject: [[[ManEntry alloc] initWithName: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 2] andSection: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1] andPath: @""] autorelease]]];
	}
}

-(void)applicationWillTerminate: (NSNotification*)notification
{
	//write the preferences
	NSMutableDictionary *root=[NSMutableDictionary dictionary];
	[root setValue: searchDirectories forKey: @"searchDirectories"];
	[root setValue: cache forKey: @"cache"];
	[root setValue: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] forKey: @"preferencesVersion"];
	[root writeToFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"] atomically: YES];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)theApplication
{
	//tell the application that it should quit when the last (only in this case) window is closed
	return YES;
}

-(CGFloat)splitView: (NSSplitView *)sender constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset
{
	//constrain the split view so you can't shrink the list all the way
	return proposedMin+90.0;
}

-(CGFloat)splitView: (NSSplitView *)sender constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)offset
{
	//constrain the split view so you can't shrink the text box all the way
	return proposedMax-200.0;
}

-(IBAction)showPreferences: (id)sender
{
	[preferences setOriginal: &searchDirectories];
	[NSApp beginSheet: [preferences window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
}

-(void)changeTab: (NSNotification*)notification
{
	[manlist setSelectedObjects: [NSArray arrayWithObject: [[notification object] manEntry]]];
}

-(IBAction)saveText: (id)sender
{
	NSSavePanel* sPanel=[NSSavePanel savePanel];
	[sPanel setRequiredFileType: @"txt"];
	[sPanel setCanSelectHiddenExtension: YES];
	[sPanel beginSheetForDirectory: nil file: nil modalForWindow: window modalDelegate: self didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo: @"text"];
}

-(IBAction)savePDF: (id)sender
{
	NSSavePanel* sPanel=[NSSavePanel savePanel];
	[sPanel setRequiredFileType: @"ps"];
	[sPanel setCanSelectHiddenExtension: YES];
	[sPanel beginSheetForDirectory: nil file: nil modalForWindow: window modalDelegate: self didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo: @"pdf"];
}

-(void)savePanelDidEnd: (NSSavePanel*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo
{
	if(returnCode==NSOKButton)
	{
		//the user clicked Save
		if([(NSString*)contextInfo isEqualToString: @"text"])
		{
			//they wanted to save the text
			[[[viewer textStorage] mutableString] writeToFile: [sheet filename] atomically: YES encoding: NSUTF8StringEncoding error: nil];
		}
		else
		{
			//they wanted to save it as a styled postscript
			ManEntry* entry=[[manlist selectedObjects] objectAtIndex: 0];
			NSString* man=[entry path];
			//concat the searchDirectories together
			
			NSTask* task=[[NSTask alloc] init];
			[task autorelease];
			[task setLaunchPath: @"/usr/bin/man"];
			//set the arguments and the output pipe
			[task setArguments: [NSArray arrayWithObjects: @"-t", man, nil]];
			[task setStandardOutput: [NSPipe pipe]];
			[task setStandardError: [NSPipe pipe]];
			NSFileHandle *file=[[task standardOutput] fileHandleForReading];
			[task launch];
			//get the output
			NSData* encodedPS=[NSData dataWithData: [file readDataToEndOfFile]];
			[encodedPS writeToFile: [sheet filename] atomically: YES];
		}
	}
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
		//only search is set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"name CONTAINS %@", searchString]];
	}
	else if(![filterString isEqualToString: @""])
	{
		//only the filter is set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"section BEGINSWITH %@", filterString]];
	}
	else
	{
		//none are set
		[manlist setFilterPredicate: nil];
	}
}

-(IBAction)filter: (id)sender
{
	//set the filterString
	[filterString autorelease];
	filterString=[[NSString stringWithFormat: @"%i", [sender indexOfSelectedItem]] retain];
	if([filterString isEqualToString: @"0"])
	{
		//All is selected
		[filterString autorelease];
		filterString=[[NSString string] retain];
	}
	
	if(![filterString isEqualToString: @""] && ![searchString isEqualToString: @""])
	{
		//both are set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"section BEGINSWITH %@ && name CONTAINS %@", filterString, searchString]];
	}
	else if(![searchString isEqualToString: @""])
	{
		//only search is set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"name CONTAINS %@", searchString]];
	}
	else if(![filterString isEqualToString: @""])
	{
		//only the filter is set
		[manlist setFilterPredicate: [NSPredicate predicateWithFormat: @"section BEGINSWITH %@", filterString]];
	}
	else
	{
		//none are set
		[manlist setFilterPredicate: nil];
	}
}

-(IBAction)update: (id)sender
{
	loaded=NO;
	//show the loader sheet
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	//force a clearing of the cache and reload from disk
	[self loadFromDisk];
	
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
	loaded=YES;
}

-(void)loadFromCache
{
	//cache is assumed to not have any duplicates because it will be created without any duplicates
	//set the status correctly whether we are loading from cache or not
	[loader loadedFromCache: YES];
	[[manlist content] removeAllObjects];
	//set up the progress bar
	[[loader progressBar] setDoubleValue: 0.0];
	[[loader progressBar] setMaxValue: 20];
	int twentieths=[cache count]/20;
	[window display];
	[[loader window] display];
	
	//iterate through the cache
	int count=0;
	for(NSArray* manItem in cache)
	{
		[self addEntry: [manItem objectAtIndex: 0] withSection: [manItem objectAtIndex: 1] andPath: [manItem objectAtIndex: 2]];
		
		count++;
		
		if(count%twentieths==0)
		{
			//update the progress bar
			[[loader progressBar] incrementBy: 1.0];
			[[loader progressBar] display];
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

-(void)loadFromDisk
{
	//set the status correctly whether we are loading from cache or not
	[loader loadedFromCache: NO];
	//clear the list
	[[manlist content] removeAllObjects];
	//set up the progress bar
	[[loader progressBar] setDoubleValue: 0.0];
	[[loader progressBar] setMaxValue: 11*[searchDirectories count]+(11*[searchDirectories count])*.5];
	[window display];
	[[loader window] display];
	
	//clear the previous cache
	[cache removeAllObjects];
	
	//get the hashmap ready that will "automatically" filter duplicates
	NSMutableDictionary* hashmap=[NSMutableDictionary dictionary];
	
	//iterate through the search directories
	for(NSString* directory in searchDirectories)
	{
		int section;
		for(section=1; section<12; section++)  //for each man section (ex. man*)
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
			else if(section==11)
			{
				addon=@"manl/";
			}
			//test to see if the directories in the preferences end with a / and if not, add one automatically
			if([directory characterAtIndex: [directory length]-1]!='/')
			{
				addon=[@"/" stringByAppendingString: addon];
			}
			NSString* path=[directory stringByAppendingString: addon];
			NSFileManager *checker=[NSFileManager defaultManager];  //used to see if sub directories exist and see the contents of them
			if([checker fileExistsAtPath: path])
			{
				//get the contents
				NSArray* contents=[checker contentsOfDirectoryAtPath: path error: NULL];
				for(NSString* man in contents)  //iterate through the contents and add them
				{
					//test and skip invisable files (ones that start with .)
					if([man characterAtIndex: 0]=='.')
					{
						//it started with a period and therefore invisable.  skip it
						continue;
					}
					NSString* section;
					NSString* name;
					//test if there is .gz extentsion and remove it
					if([[man pathExtension] isEqualToString: @"gz"])
					{
						//there is an .gz extension
						NSString* neuter=[man stringByReplacingOccurrencesOfString: @".gz" withString: @""];
						//parse out the section and format
						section=[[neuter componentsSeparatedByString: @"."] lastObject];
						name=[neuter substringToIndex: ([neuter length]-[section length]-1)];
					}
					else
					{
						//there is NO .gz extension
						//parse out the section and format
						section=[[man componentsSeparatedByString: @"."] lastObject];
						name=[man substringToIndex: ([man length]-[section length]-1)];
					}
					NSString* manPath=[path stringByAppendingString: man];
					[hashmap setValue: [NSArray arrayWithObjects: name, section, manPath, nil] forKey: [name stringByAppendingString: section]];
					//we will add the values to the actual list later, for now add it to the hashmap dictionary thing
				}
			}
			//update the progress bar
			[[loader progressBar] incrementBy: 1.0];
			[[loader progressBar] display];
		}
	}
	
	//now go through the hashmap dictionary and create the cache and add the items to the actual list
	NSArray* manValues=[hashmap allValues];
	int fraction=[manValues count]/((11*[searchDirectories count])*.5);
	int count=0;
	for(NSArray* manItem in manValues)
	{
		//add the item to the cache
		[cache addObject: manItem];
		//add the item to the list
		[self addEntry: [manItem objectAtIndex: 0] withSection: [manItem objectAtIndex: 1] andPath: [manItem objectAtIndex: 2]];
		
		count++;
		
		if(count%fraction==0)
		{
			//update the progress bar
			[[loader progressBar] incrementBy: 1.0];
			[[loader progressBar] display];
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
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[searchDirectories release];
	[cache release];
	//[tabs release];
	[searchString release];
	[filterString release];
	[super dealloc];
}

@end
