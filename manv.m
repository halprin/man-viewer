//
//  manpath_helper.c
//  Man Viewer
//
//  This code is never compiled into the actual Man Viewer application.
//  It is a helper program to be installed into /usr/local/bin so it is easy for a user to open Man Viewer with a specified manpage.
//
//  Created by Peter Kendall on 1/10/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NSDictionary* getLanguageStrings(NSString* languageCode);

int main(int argc, const char* argv[])
{
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
	NSString* manpage=nil;
	NSString* section=nil;
	NSDistantObject* proxy=nil;
	
	//figure out what language we should use
	NSString* languageCode=[[[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"] objectAtIndex: 0];
	NSDictionary* languageStrings=getLanguageStrings(languageCode);
	
	//test the command line input
	if(argc<2 || argc>3)
	{
		//we have either too little or too many command line arguments
		//quit
		NSLog([languageStrings valueForKey: @"IncorrectArguments"]);
		NSLog([languageStrings valueForKey: @"Usage"]);
		return -1;
	}
	else if(argc==2)
	{
		manpage=[NSString stringWithCString: argv[1] encoding: NSISOLatin1StringEncoding];
		NSLog([languageStrings valueForKey: @"Lookup"], manpage);
	}
	else if(argc==3)
	{
		manpage=[NSString stringWithCString: argv[2] encoding: NSISOLatin1StringEncoding];
		section=[NSString stringWithCString: argv[1] encoding: NSISOLatin1StringEncoding];
		NSLog([languageStrings valueForKey: @"LookupSection"], manpage, section);
	}
	else
	{
		//we should never get to this point in code
		//if so, bomb out
		NSLog([languageStrings valueForKey: @"IllegalPath"]);
		return -2;
	}
	
	//launch Man Viewer
	BOOL success=[[NSWorkspace sharedWorkspace] launchApplication: @"Man Viewer"];
	if(!success)
	{
		//the launch failed
		NSLog([languageStrings valueForKey: @"FailedLaunch"]);
		return -3;
	}
	
	//continue to ask for the proxy of the specified name until we get it (and therefore not nil)
	while((proxy=[NSConnection rootProxyForConnectionWithRegisteredName: @"PAKManViewer" host: nil])==nil);
	//we now have the proxy (that means Man Viewer has loaded up enough to start recieving calls)
	//send the command
	[proxy ipcSelectManPage: manpage withSection: section];
	
	//clean up
    [pool drain];
    return 0;
}

NSDictionary* getLanguageStrings(NSString* languageCode)
{
	NSMutableDictionary* languageStrings=[NSMutableDictionary dictionary];
	
	//test the language code
	if([languageCode isEqualToString: @"de"] || [languageCode isEqualToString: @"ger"])
	{
		//the language is German
		[languageStrings setValue: @"Falsche Argumente.  Beenden!" forKey: @"IncorrectArguments"];
		[languageStrings setValue: @"Nutzung:  $ manv [Abschnitt] man-Seite" forKey: @"Usage"];
		[languageStrings setValue: @"Nachschlagen %@" forKey: @"Lookup"];
		[languageStrings setValue: @"Nachschlagen %@ (%@)" forKey: @"LookupSection"];
		[languageStrings setValue: @"Unerwartete illegale Hinrichtung Weg angetroffenen.  Beenden!" forKey: @"IllegalPath"];
		[languageStrings setValue: @"Man Viewer nicht starten.  Beenden!" forKey: @"FailedLaunch"];
	}
	else
	{
		//default to English
		[languageStrings setValue: @"Incorrect arguments.  Quitting!" forKey: @"IncorrectArguments"];
		[languageStrings setValue: @"Usage:  $ manv [section] manpage" forKey: @"Usage"];
		[languageStrings setValue: @"Looking up %@" forKey: @"Lookup"];
		[languageStrings setValue: @"Looking up %@ (%@)" forKey: @"LookupSection"];
		[languageStrings setValue: @"Unexpected illegal execution path encountered.  Quitting!" forKey: @"IllegalPath"];
		[languageStrings setValue: @"Man Viewer failed to launch.  Quitting!" forKey: @"FailedLaunch"];
	}
	
	//return the translation dictionary
	return languageStrings;
}
