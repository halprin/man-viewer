//
//  Loader.m
//  Man Viewer
//
//  Created by Peter Kendall on 1/31/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "Loader.h"


@implementation Loader

-(NSWindow*)window
{
	return window;
}

-(NSProgressIndicator*)progressBar
{
	return progress;
}

-(void)loadedFromCache: (BOOL)flag
{
	if(flag)
	{
		[status setStringValue: @"Loading man pages...  (cached)"];
	}
	else
	{
		[status setStringValue: @"Loading man pages..."];
	}
}

@end
