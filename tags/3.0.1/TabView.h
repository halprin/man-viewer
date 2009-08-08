//
//  TabView.h
//  Man Viewer
//
//  Created by Peter Kendall on 3/30/08.
//  Copyright 2008 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ManEntry.h"
//#import "TabCollectionView.h"


@interface TabView : NSView
{
	ManEntry* manEntry;
	NSImage* selectedImage;
	NSImage* notSelectedImage;
	NSImage* hoverImage;
	BOOL selected;
	BOOL hovered;
	BOOL inDropDown;
	NSTextField* text;
	NSButton* close;
	NSTrackingArea* tracker;
}
-(BOOL)selected;
-(void)setSelected: (BOOL)select;
-(void)closeSelf: (id)sender;
-(void)mouseEntered: (NSEvent*)theEvent;
-(void)mouseExited: (NSEvent*)theEvent;
-(void)mouseDown: (NSEvent*)theEvent;
-(ManEntry*)manEntry;
-(void)setManEntry: (ManEntry*)newValue;
-(void)closeEnabled: (BOOL)flag;
-(void)dealloc;
@end
