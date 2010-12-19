//
//  PKTextView.m
//  Man Viewer
//
//  Created by Peter Kendall on 12/4/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "PKTextView.h"


@implementation PKTextView

-(void)viewDidEndLiveResize
{
	//we just finished resizing, send out a notification that we are done
	[[NSNotificationCenter defaultCenter] postNotificationName: @"PKTextViewDidEndLiveResize" object: self];
	//finally, send this up to super
	[super viewDidEndLiveResize];
}

@end
