//
//  PKTabCell.m
//  Man Viewer
//
//  Created by Peter Kendall on 11/6/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import "PKTabCell.h"


@implementation PKTabCell

-(PKTabCell*)init
{
	self=[super init];
	return self;
}

-(PKTabCell*)initWithCoder: (NSCoder*)decoder
{
	self=[super initWithCoder: decoder];
	return self;
}

-(PKTabCell*)initTextCell: (NSString*)aString
{
	self=[super initTextCell: aString];
	return self;
}

-(PKTabCell*)initImageCell: (NSImage*)anImage;
{
	self=[super initImageCell: anImage];
	return self;
}

-(NSRect)drawTitle: (NSAttributedString*)title withFrame: (NSRect)frame inView: (NSView*)controlView
{
	//modify the frame so that when we call the super equivalent method, it draws the title to the right of the close button and not on top of it
	frame.origin.x=20.0;
	frame.size.width=84.0;
	//call the super now with the modified frame
	NSRect superRect=[super drawTitle: title withFrame: frame inView: controlView];
	
	return superRect;
}

@end
