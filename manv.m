#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main(int argc, const char* argv[])
{
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
	NSString* manpage=nil;
	NSString* section=nil;
	NSDistantObject* proxy=nil;
	
	//test the command line input
	if(argc<2 || argc>3)
	{
		//we have either too little or too many command line arguments
		//quit
		NSLog(@"Incorrect arguments.  Quitting!");
		NSLog(@"Usage:  $ manv [section] manpage");
		return -1;
	}
	else if(argc==2)
	{
		manpage=[NSString stringWithCString: argv[1] encoding: NSISOLatin1StringEncoding];
		NSLog(@"Looking up %@", manpage);
	}
	else if(argc==3)
	{
		manpage=[NSString stringWithCString: argv[2] encoding: NSISOLatin1StringEncoding];
		section=[NSString stringWithCString: argv[1] encoding: NSISOLatin1StringEncoding];
		NSLog(@"Looking up %@ (%@)", manpage, section);
	}
	else
	{
		//we should never get to this point in code
		//if so, bomb out
		NSLog(@"Unexpected illegal path encountered.  Quitting!");
		return -2;
	}
	
	//launch Man Viewer
	[[NSWorkspace sharedWorkspace] launchApplication: @"Man Viewer"];
	
	//continue to ask for the proxy of the specified name until we get it (and therefore not nil)
	while((proxy=[NSConnection rootProxyForConnectionWithRegisteredName: @"PAKManViewer" host: nil])==nil);
	//we now have the proxy (that means Man Viewer has loaded up enough to start recieving calls)
	//send the command
	[proxy ipcSelectManPage: manpage withSection: section];
	
	//clean up
    [pool drain];
    return 0;
}
