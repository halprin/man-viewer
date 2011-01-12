//
//  Loader.h
//  Man Viewer
//
//  Created by Peter Kendall on 1/31/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Loader : NSObject
{
	IBOutlet NSProgressIndicator* progress;
	IBOutlet NSWindow* window;
	IBOutlet NSTextField* status;
}
-(NSWindow*)window;
-(NSProgressIndicator*)progressBar;
-(void)incrementProgressBarBy: (NSNumber*)delta;
-(void)loadedFromCache: (BOOL)flag;
@end
