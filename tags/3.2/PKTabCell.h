//
//  PKTabCell.h
//  Man Viewer
//
//  Created by Peter Kendall on 11/6/10.
//  Copyright 2010 @PAK Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKTabCell : NSButtonCell
{
	
}
-(PKTabCell*)init;
-(PKTabCell*)initWithCoder: (NSCoder*)decoder;
-(PKTabCell*)initTextCell: (NSString*)aString;
-(PKTabCell*)initImageCell: (NSImage*)anImage;
-(NSRect)drawTitle: (NSAttributedString*)title withFrame: (NSRect)frame inView: (NSView*)controlView;
@end
