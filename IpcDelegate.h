//
//  IpcDelegate.h
//  Man Viewer
//
//  Created by Peter Kendall on 1/12/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IpcDelegate : NSObject
{
	id reference;
}
-(IpcDelegate*)initWithDelegate: (id)delegate;
-(void)ipcSelectManPage: (NSString*)manpage withSection: (NSString*)section;

@end
