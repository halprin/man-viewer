//
//  IpcDelegate.m
//  Man Viewer
//
//  Created by Peter Kendall on 1/12/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "IpcDelegate.h"


@implementation IpcDelegate

-(IpcDelegate*)initWithDelegate: (id)delegate
{
	if(self=[super init])
	{
		reference=delegate;
	}
	return self;
}

-(void)ipcSelectManPage: (NSString*)manpage withSection: (NSString*)section
{
	[reference selectEntry: manpage withSection: section];
}

@end
