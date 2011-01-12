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

-(void)incrementProgressBarBy: (NSNumber*)delta
{
	[[self progressBar] incrementBy: [delta doubleValue]];
}

-(void)loadedFromCache: (BOOL)flag
{
	if(flag)
	{
		[status setStringValue: [[NSBundle mainBundle] localizedStringForKey: @"LoadingManPagesCached" value: @"Loading man pages...  (cached)" table: nil]];
	}
	else
	{
		[status setStringValue: [[NSBundle mainBundle] localizedStringForKey: @"LoadingManPages" value: @"Loading man pages..." table: nil]];
	}
}

@end
