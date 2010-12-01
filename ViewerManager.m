#import "ViewerManager.h"
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>


@implementation ViewerManager

-(ViewerManager*)init
{
	if(self=[super init])
	{
		tabManList=[[NSMutableArray array] retain];
		//add the first tab model since there is one by default
		[tabManList addObject: [[ManEntry alloc] init]];
		searchDirectories=[[NSMutableArray array] retain];
		searchString=[[NSString string] retain];
		filterString=[[NSString string] retain];
		cache=[[NSMutableArray array] retain];
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
		[[[viewer textStorage] mutableString] setString: [[NSBundle mainBundle] localizedStringForKey: @"SelectManPage" value: @"Please select a man page from the list on the left." table: nil]];
		return;
	}
	//scroll to the top so that once every new manpage is selected, it starts at the top
	[viewer scrollRangeToVisible: NSMakeRange(0, 0)];
	
	//get the ManEntry
	ManEntry* entry=[[manlist selectedObjects] objectAtIndex: 0];
	
	//change the current tab title
	[tabManList replaceObjectAtIndex: [tabBar selectedTabIndex] withObject: entry];
	[tabBar setSelectedTabTitle: [NSString stringWithFormat: @"%@ (%@)", [entry name], [entry section]]];
	
	//actually display the manual
	[self displayManPageFromManEntry: entry];
}

-(void)displayManPageFromManEntry: (ManEntry*)entry
{
	//check to see if this entry is blank or there is something to it
	if(![[entry name] isEqualToString: @""] && ![[entry section] isEqualToString: @""] && ![[entry path] isEqualToString: @""])
	{
		//the entry is a real manpage, display it
		NSString* man=[entry path];
		
		NSTask* task=[[NSTask alloc] init];
		[task autorelease];
		[task setLaunchPath: @"/usr/bin/man"];
		//set the arguments and the output pipe
		[task setArguments: [NSArray arrayWithObjects: man, nil]];
		//[task setEnvironment: [NSDictionary dictionaryWithObjectsAndKeys: @"40", @"COLUMNS", nil]];
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
			[[[viewer textStorage] mutableString] setString: [[NSBundle mainBundle] localizedStringForKey: @"ManPageNotExist" value: @"That man page does not exist!" table: nil]];
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
			[task setEnvironment: [NSDictionary dictionaryWithObjectsAndKeys: @"40", @"COLUMNS", nil]];
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
			[[[viewer textStorage] mutableString] setString: [[NSBundle mainBundle] localizedStringForKey: @"ManPageNotExist" value: @"That man page does not exist!" table: nil]];
		}
		else
		{
			[[[viewer textStorage] mutableString] setString: [contents componentsJoinedByString: @""]];
		}
	}
	else
	{
		//the entry was a blank default, so display the text to select something from the left
		[[[viewer textStorage] mutableString] setString: [[NSBundle mainBundle] localizedStringForKey: @"SelectManPage" value: @"Please select a man page from the list on the left." table: nil]];
	}
}

-(NSString*)tableView: (NSTableView*)aTableView toolTipForCell: (NSCell*)aCell rect: (NSRectPointer)rect tableColumn: (NSTableColumn*)aTableColumn row: (NSInteger)row mouseLocation: (NSPoint)mouseLocation
{
	//return back the path to that man page for the tooltip
	return [[[manlist arrangedObjects] objectAtIndex: row] path];
}

-(void)revealInFinder: (id)sender
{
	//the user just control/right clicked on an entry and selected Reveal in Finder from the context menu
	[[NSWorkspace sharedWorkspace] selectFile: [[[manlist selectedObjects] objectAtIndex: 0] path] inFileViewerRootedAtPath: nil];
}

-(void)addEntry: (NSString*)name withSection: (NSString*)section andPath: (NSString*)path
{
	//this method assumes that no duplicates will be handed to it
	ManEntry* newOne=[[[ManEntry alloc] initWithName: name andSection: section andPath: path] autorelease];
	//[manlist addObject: newOne];
	[manlist performSelectorOnMainThread: @selector(addObject:) withObject: newOne waitUntilDone: YES];
}

-(void)selectEntry: (NSString*)name withSection: (NSString*)section
{
	//given the passed in arguments, select that entry in the list
	[self selectEntry: [[[ManEntry alloc] initWithName: name andSection: ((section!=nil)?section:@"") andPath: @""] autorelease]];
}

-(void)selectEntry: (ManEntry*)entry
{
	//select the entrie(s) equal to entry
	[manlist setSelectedObjects: [NSArray arrayWithObject: entry]];
	//it is possible that multiple items were selected, make this just 1
	[manlist setSelectionIndex: [manlist selectionIndex]];
	//test if we have even selected an item, and if so, then only do we scroll to the visbile item
	if([manlist selectionIndex]!=NSNotFound)
	{
		//an item was actually selected
		//scroll to view the newly selected entry
		[entries scrollRowToVisible: [manlist selectionIndex]];
	}
}

-(void)applicationDidFinishLaunching: (NSNotification*)notification
{	
	//set the font
	[[viewer textStorage] setFont: [NSFont fontWithName: @"Courier" size: 12.0]];
	//set the predicate
	
	//set up the delegate for the tab bar
	[tabBar setDelegate: self];
	//start up the IPC server
	ipcDelegate=[[IpcDelegate alloc] initWithDelegate: self];
	NSConnection* serverConnection=[NSConnection defaultConnection];
	[serverConnection setRootObject: ipcDelegate];
	[serverConnection registerName: @"PAKManViewer"];
	
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
	
	//set ourselves up for listening for the notification when the man pages are fully loaded
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(finishApplicationLoad) name: PKNotificationManPagesLoaded object: self];
	
	//do we want to force a load from the disk?
	CGEventRef event=CGEventCreate(NULL);
	CGEventFlags mods=CGEventGetFlags(event);
	
	//test if a cache exists
	NSString* version=[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
	if(cache!=nil && [cache count]>0 && !(mods & kCGEventFlagMaskCommand) && preferencesVersion!=nil && [preferencesVersion isEqualToString: version])
	{
		//the cache exists, has at least one item, or was not forced to load from disk; so load from cache
		[self loadManPages: YES];
	}
	else
	{
		//load from disk
		[cache autorelease];
		cache=[[NSMutableArray array] retain];
		//now do the heavy lifting to read in the man pages
		[self loadManPages: NO];
	}
	
	//destroy the event that tests if the command key was pressed
	CFRelease(event);
}

-(void)finishApplicationLoad
{
	//test if any command arguments were passed to this Cocoa application
	//supposed to be a name of a man page that is automatically selected
	if([[[NSProcessInfo processInfo] arguments] count]==2)
	{
		NSLog([[NSBundle mainBundle] localizedStringForKey: @"AutoLookup" value: @"Auto lookup %@" table: nil], [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1]);
		//[manlist setSelectedObjects: [NSArray arrayWithObject: [[[ManEntry alloc] initWithName: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1] andSection: @"" andPath: @""] autorelease]]];
		//it is possible that multiple items were selected, make this just 1
		//[manlist setSelectionIndex: [manlist selectionIndex]];
		
		[self selectEntry: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1] withSection: nil];
	}
	else if([[[NSProcessInfo processInfo] arguments] count]==3)
	{
		NSLog([[NSBundle mainBundle] localizedStringForKey: @"AutoLookupSection" value: @"Auto lookup %@ (%@)" table: nil], [[[NSProcessInfo processInfo] arguments] objectAtIndex: 2], [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1]);
		//[manlist setSelectedObjects: [NSArray arrayWithObject: [[[ManEntry alloc] initWithName: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 2] andSection: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1] andPath: @""] autorelease]]];
		
		[self selectEntry: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 2] withSection: [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1]];
	}
	
	//remove ourselves from listening to this notification since we are done loading
	[[NSNotificationCenter defaultCenter] removeObserver: self name: PKNotificationManPagesLoaded object: self];
}

-(void)dismissLoader
{
	//enable the close window menu item
	[closeWindowMenuItem setEnabled: YES];
	//dismiss the loader sheet
	[[loader window] orderOut: self];
	[NSApp endSheet: [loader window] returnCode: 0];
	[[loader progressBar] stopAnimation: self];
	loaded=YES;
}

-(void)applicationWillTerminate: (NSNotification*)notification
{
	//write the preferences
	
	//Bad version
	/*
	NSMutableDictionary *root=[NSMutableDictionary dictionary];
	[root setValue: searchDirectories forKey: @"searchDirectories"];
	[root setValue: cache forKey: @"cache"];
	[root setValue: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] forKey: @"preferencesVersion"];
	[root writeToFile: [NSHomeDirectory() stringByAppendingString: @"/Library/Preferences/com.atPAK.Man Viewer.plist"] atomically: YES];
	*/
	
	
	//Good version
	[[NSUserDefaults standardUserDefaults] setObject: searchDirectories forKey: @"searchDirectories"];
	[[NSUserDefaults standardUserDefaults] setObject: cache forKey: @"cache"];
	[[NSUserDefaults standardUserDefaults] setObject: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] forKey: @"preferencesVersion"];
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

-(IBAction)installCommandLineTools: (id)sender
{
	//tell the user what we are about to do
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"InstallCommandLineTool" value: @"Installing Command Line Tool" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], nil, window, self, nil, @selector(authorizeInstall:returnCode:contextInfo:), nil, [[NSBundle mainBundle] localizedStringForKey: @"CommandLineToolDescription" value: @"Man Viewer will now install manv, a command line tool, into /usr/local/bin/.  manv makes it easy to look up man pages in Man Viewer from the command line.  More details can be found in the Read Me file." table: nil]);
}

-(void)authorizeInstall: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo
{
	//see if the user said OK or no
	if(returnCode==NSAlertAlternateReturn)
	{
		//the cancel button was pressed
		return;
	}
	
	//create the reference to the authorization "object"
	AuthorizationRef authorization;
	//create the authorization with no rights
	//NULL=start with no rights
	//kAuthorizationEmptyEnvironment=no need to specify a specialized environment so use the default
	//kAuthorizationFlagDefaults=no special flags/options necisary
	//&authorization=the references to the authorization reference
	OSStatus status=AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorization);
	
	//check if the above action was allowed and sucessful
	if(status!=errAuthorizationSuccess)
	{
		//access denied!
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"AuthorizationDenied" value: @"Authorization denied!" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], nil, nil, window, self, nil, nil, nil, [[NSBundle mainBundle] localizedStringForKey: @"ManvNotInstalled" value: @"manv was not installed." table: nil]);
		return;
	}
	
	//create a single right item
	//kAuthorizationRightExecute=the name of the right we want, which is able to execute something
	//0=the length of the value which is the next argument
	//NULL=no value specified, but some of the documentation says to use the path of the program you want to execute
	//0=default and only setting for flags, seem to be some reserved option bits for Apple
	AuthorizationItem item={kAuthorizationRightExecute, 0, NULL, 0};
	//create a auth right request with the above right
	AuthorizationRights right={1, &item};
	//set the flags to have it so that we have the default, we allow user interaction, and preauthorize the extended rights
	AuthorizationFlags flags=kAuthorizationFlagDefaults|kAuthorizationFlagInteractionAllowed|kAuthorizationFlagPreAuthorize|kAuthorizationFlagExtendRights;
	
	//now ask for the rights
	//authorization=again referencing the reference so this function knows what it is dealing with
	//&right=tell the function what rights we want
	//kAuthorizationEmptyEnvironment=again, we don't need a special environment
	//flags=tells the function what kind of options we want along with the request
	//NULL=aparently we don't care about the actual granted rights and assume we get them
	status=AuthorizationCopyRights(authorization, &right, kAuthorizationEmptyEnvironment, flags, NULL);
	
	//check if the above action was allowed and sucessful
	if(status!=errAuthorizationSuccess)
	{
		//access denied!
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"AuthorizationDenied" value: @"Authorization denied!" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], nil, nil, window, self, nil, nil, nil, [[NSBundle mainBundle] localizedStringForKey: @"ManvNotInstalled" value: @"manv was not installed." table: nil]);
		return;
	}
	
	//now we call the outside program to do the actual copy
	
	//specify the arguments that we will pass to cp
	char* arguments[]={[[[NSBundle mainBundle] pathForResource: @"manv" ofType: @""] cStringUsingEncoding: NSISOLatin1StringEncoding], "/usr/local/bin/", NULL};
	//authorization=the authorization reference so this function knows what we are talking about
	//"/bin/cp"=the full path to the UNIX copy program
	//kAuthorizationFlagDefaults=wwe don't need any special flags so specify the default
	//arguments=pass in the agruments to the cp program
	//NULL=we don't care about getting output back from cp
	status=AuthorizationExecuteWithPrivileges(authorization, "/bin/cp", kAuthorizationFlagDefaults, arguments, NULL);
	
	//check if the above action was allowed and sucessful
	if(status!=errAuthorizationSuccess)
	{
		//access denied!
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"AuthorizationDenied" value: @"Authorization denied!" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], nil, nil, window, self, nil, nil, nil, [[NSBundle mainBundle] localizedStringForKey: @"ManvNotInstalled" value: @"manv was not installed." table: nil]);
		return;
	}
	
	//everything worked and we are done, clean up
	//authorization=tell this function which auth to close up
	//kAuthorizationFlagDestroyRights=no special flags needed
	status=AuthorizationFree(authorization, kAuthorizationFlagDefaults);
	
	//check if the above action was successful
	if(status!=errAuthorizationSuccess)
	{
		//we are boned!  Why couldn't the free command just do what it's told!  Just kill it!
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"AuthorizationDenied" value: @"Authorization denied!" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], nil, nil, window, self, nil, nil, nil, [[NSBundle mainBundle] localizedStringForKey: @"ManvNotInstalled" value: @"manv was not installed." table: nil]);
		return;
	}
	
	//everything truely worked!
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"ManvInstalled" value: @"manv Installed Successfully" table: nil], [[NSBundle mainBundle] localizedStringForKey: @"OK" value: @"OK" table: nil], nil, nil, window, self, nil, nil, nil, [[NSBundle mainBundle] localizedStringForKey: @"ManvInstalledDescription" value: @"manv was installed /usr/local/bin/.  You can now use manv directly from the Terminal.\nUsage:  manv [section] manpage" table: nil]);
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

-(void)willSelectTabAtIndex: (NSNumber*)index
{
	//select the man page in the list if I can
	[self selectEntry: [tabManList objectAtIndex: [index unsignedIntegerValue]]];
	//actually display the manual
	[self displayManPageFromManEntry: [tabManList objectAtIndex: [index unsignedIntegerValue]]];
}

-(void)willCloseTabAtIndex: (NSNumber*)index
{
	//a tab is closing so delete that object from the tabManList
	[tabManList removeObjectAtIndex: [index unsignedIntegerValue]];
	//test to see if there is only one more tab left, and change the menus
	if([tabBar tabCount]==2)  //2 because it is about to be 1, hence _will_CloseTabAtIndex
	{
		//move the command + W to the correct menu
		[closeTabMenuItem setKeyEquivalent: @""];
		[closeWindowMenuItem setKeyEquivalent: @"w"];
		//disable close tab since we don't want to allow closing the last tab
		[closeTabMenuItem setEnabled: NO];
	}
}

-(IBAction)newTab: (id)sender
{
	[tabBar addTabWithTitle: @"Untitled"];
	[tabManList addObject: [[ManEntry alloc] init]];
	//now select that newly added tab
	[tabBar selectTabAtIndex: [tabManList count]-1];
	//test if we have two tabs in the tab bar since I don't want this executing everytime we add a new tab
	if([tabBar tabCount]==2)
	{
		//move the command + W to the correct menu
		[closeWindowMenuItem setKeyEquivalent: @"W"];
		[closeTabMenuItem setKeyEquivalent: @"w"];
		[closeTabMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
		//enable the close tab since we want to allow closing tabs since there is more than one
		[closeTabMenuItem setEnabled: YES];
	}
}

-(IBAction)closeTab: (id)sender
{
	[tabBar closeTabAtIndex: [tabBar selectedTabIndex]];
}

-(IBAction)nextTab: (id)sender
{
	NSUInteger previousSelectedTab=(([tabBar selectedTabIndex]<[tabBar tabCount]-1)?[tabBar selectedTabIndex]+1:0);
	[tabBar selectTabAtIndex: previousSelectedTab];
}

-(IBAction)previousTab: (id)sender
{
	NSUInteger nextSelectedTab=(([tabBar selectedTabIndex]>0)?[tabBar selectedTabIndex]-1:[tabBar tabCount]-1);
	[tabBar selectTabAtIndex: nextSelectedTab];
}

-(IBAction)update: (id)sender
{
	//force a clearing of the cache and reload from disk
	[self loadManPages: NO];
}

-(void)loadManPages: (BOOL)cached
{
	//clear the list
	[[manlist content] removeAllObjects];
	
	//show the loader sheet
	[[loader progressBar] setUsesThreadedAnimation: YES];
	[[loader progressBar] startAnimation: self];
	[NSApp beginSheet: [loader window] modalForWindow: window modalDelegate: self didEndSelector: nil contextInfo: nil];
	
	if(cached)
	{
		//set the status correctly whether we are loading from cache or not
		[loader loadedFromCache: YES];
		//set up the progress bar
		[[loader progressBar] setDoubleValue: 0.0];
		[[loader progressBar] setMaxValue: 20];
		[window display];
		[[loader window] display];
		
		//Worker thread
		[NSThread detachNewThreadSelector: @selector(loadFromCache) toTarget: self withObject: nil];
	}
	else
	{
		//set the status correctly whether we are loading from cache or not
		[loader loadedFromCache: NO];
		//set up the progress bar
		[[loader progressBar] setDoubleValue: 0.0];
		[[loader progressBar] setMaxValue: 11*[searchDirectories count]+(11*[searchDirectories count])*.5];
		[window display];
		[[loader window] display];
		
		//clear the previous cache
		[cache removeAllObjects];
		
		//Worker thread
		[NSThread detachNewThreadSelector: @selector(loadFromDisk) toTarget: self withObject: nil];
	}
}

-(void)finishManPagesLoad
{
	//update the progress bar
	[[loader progressBar] setDoubleValue: [[loader progressBar] maxValue]];
	
	//set the sort type
	NSSortDescriptor* sorter=[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];
	[sorter autorelease];
	[manlist setSortDescriptors: [NSArray arrayWithObject: sorter]];
	
	[manlist rearrangeObjects];
	
	//dismiss the loader sheet
	[self dismissLoader];
	
	//send out the notification that we are done loading man pages
	[[NSNotificationCenter defaultCenter] postNotificationName: PKNotificationManPagesLoaded object: self];
}

-(void)loadFromCache
{
	//NSAutoreleasePool for the seperate thread
	NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
	
	//cache is assumed to not have any duplicates because it will be created without any duplicates
	int twentieths=[cache count]/20;
	
	//iterate through the cache
	int count=0;
	for(NSArray* manItem in cache)
	{
		[self addEntry: [manItem objectAtIndex: 0] withSection: [manItem objectAtIndex: 1] andPath: [manItem objectAtIndex: 2]];
		
		count++;
		
		if(count%twentieths==0)
		{
			//update the progress bar
			[loader performSelectorOnMainThread: @selector(incrementProgressBarBy:) withObject: [NSNumber numberWithDouble: 1.0] waitUntilDone: YES];
		}
	}
	
	[self performSelectorOnMainThread: @selector(finishManPagesLoad) withObject: nil waitUntilDone: NO];
	
	[pool drain];
}

-(void)loadFromDisk
{
	//NSAutoreleasePool for the seperate thread
	NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
	
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
			[loader performSelectorOnMainThread: @selector(incrementProgressBarBy:) withObject: [NSNumber numberWithDouble: 1.0] waitUntilDone: YES];
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
			[loader performSelectorOnMainThread: @selector(incrementProgressBarBy:) withObject: [NSNumber numberWithDouble: 1.0] waitUntilDone: YES];
		}
	}
	
	[self performSelectorOnMainThread: @selector(finishManPagesLoad) withObject: nil waitUntilDone: NO];
	
	[pool drain];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[ipcDelegate release];
	[searchDirectories release];
	[cache release];
	[searchString release];
	[filterString release];
	[super dealloc];
}

@end
