//
//  ManEntry.m
//  Man Viewer
//
//  Created by Peter Kendall on 2/29/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import "ManEntry.h"


@implementation ManEntry

-(ManEntry*)init
{
	if(self=[super init])
	{
		[self setName: @"pak"];
		[self setSection: @"33"];
	}
	return self;
}

-(ManEntry*)initWithName: (NSString*)aName andSection: (NSString*)aSection
{
	if(self=[super init])
	{
		[self setName: aName];
		[self setSection: aSection];
	}
	return self;
}

-(NSString*)name
{
	return name;
}

-(NSString*)section
{
	return section;
}

-(void)setName: (NSString*)aName
{
	[name autorelease];
	name=[aName retain];
}

-(void)setSection: (NSString*)aSection
{
	[section autorelease];
	section=[aSection retain];
}

-(BOOL)isEqual: (id)anObject
{
	if([[anObject name] isEqualToString: [self name]] && [[anObject section] isEqualToString: [self section]])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

-(void)dealloc
{
	[name release];
	[section release];
	[super dealloc];
}

@end
