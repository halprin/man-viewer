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
		[self setName: @""];
		[self setSection: @""];
		[self setPath: @""];
	}
	return self;
}

-(ManEntry*)initWithName: (NSString*)aName andSection: (NSString*)aSection andPath: (NSString*)aPath
{
	if(self=[super init])
	{
		[self setName: aName];
		[self setSection: aSection];
		[self setPath: aPath];
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

-(NSString*)path
{
	return path;
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
-(void)setPath: (NSString*)aPath
{
	[path autorelease];
	path=[aPath retain];
}

-(BOOL)isEqual: (id)anObject
{
	if([[anObject name] isEqualToString: [self name]] && ([[self section] isEqualToString: @""] || [[anObject section] isEqualToString: @""] || [[anObject section] isEqualToString: [self section]]))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

-(NSString*)hash
{
	return [[self name] stringByAppendingString: [self section]];
}

-(void)dealloc
{
	[name release];
	[section release];
	[path release];
	[super dealloc];
}

@end
