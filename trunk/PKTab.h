//
//  PKTab.h
//  Man Viewer
//
//  Created by Peter Kendall on 11/3/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKTab : NSButton
{
	NSButton* closeButton;
	NSTrackingArea* tracker;
	BOOL selected;
	BOOL forceHideCloseButton;
	BOOL cursorInside;
	id delegate;
}
-(PKTab*)initWithFrame: (NSRect)frameRect;
-(void)setDelegate: (id)newDelegate;
-(void)selectTab;
-(void)unselectTab;
-(void)closeTab;
-(void)hideCloseButton: (BOOL)flag;
@end
