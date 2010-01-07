//
//  ManEntry.h
//  Man Viewer
//
//  Created by Peter Kendall on 2/29/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ManEntry : NSObject
{
	NSString* name;
	NSString* section;
	NSString* path;
}
-(ManEntry*)init;
-(ManEntry*)initWithName: (NSString*)aName andSection: (NSString*)aSection andPath: (NSString*)aPath;
-(NSString*)name;
-(NSString*)section;
-(NSString*)path;
-(void)setName: (NSString*)aName;
-(void)setSection: (NSString*)aSection;
-(void)setPath: (NSString*)aPath;
-(BOOL)isEqual: (id)anObject;
-(NSString*)hash;
-(void)dealloc;
@end
