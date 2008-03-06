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

}
-(ManEntry*)init;
-(ManEntry*)initWithName: (NSString*)aName andSection: (NSString*)aSection;
-(NSString*)name;
-(NSString*)section;
-(void)setName: (NSString*)aName;
-(void)setSection: (NSString*)aSection;
-(BOOL)isEqual: (id)anObject;
-(void)dealloc;
@end
