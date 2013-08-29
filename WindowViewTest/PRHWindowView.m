//
//  PRHWindowView.m
//  WindowViewTest
//
//  Created by Peter Hosey on 2013-08-28.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import "PRHWindowView.h"

#include <Carbon/Carbon.h>

@implementation PRHWindowView
{
	NSString *_title;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _title = @"Ceci n'es pas une fenêtre";
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

	NSRect frameRect = self.bounds;

	static const CGFloat shadowRadius = 20.0;
	CGContextTranslateCTM(context, shadowRadius, shadowRadius);
	frameRect.size.width -= shadowRadius * 2.0;
	frameRect.size.height -= shadowRadius * 2.0;

	//Hard-coded because I don't know of a public API to compute a content rect from a frame rect (Appearance Mgr and HITheme expect you to go the other way).
	NSSize titleSize = { frameRect.size.width, 22.0 };
	NSRect contentRect = frameRect;
	contentRect.size.height -= titleSize.height;

	struct HIThemeWindowDrawInfo windowDrawInfo = {
		.version = 0,
		.state = kThemeStateActive,
		.windowType = kThemeDocumentWindow,
		.attributes = kThemeWindowHasFullZoom | kThemeWindowHasCloseBox | kThemeWindowHasCollapseBox | kThemeWindowHasTitleText,
		.titleHeight = titleSize.height,
		.titleWidth = titleSize.width,
	};

	CGContextSetShadowWithColor(context, CGSizeZero, shadowRadius, CGColorGetConstantColor(kCGColorBlack));

	CGContextBeginTransparencyLayer(context, NULL);

	HIThemeSetFill(kThemeBrushModelessDialogBackgroundActive, /*info*/ NULL, context, kHIThemeOrientationInverted);
	HIShapeRef shape = NULL;
	OSStatus err = HIThemeGetWindowShape(&contentRect, &windowDrawInfo, kWindowStructureRgn, &shape);
	if (err == noErr) {
		//Apparently HIShapeReplacePathInCGContext isn't subject to the CTM, so we need to re-translate it.
		HIMutableShapeRef mutableShape = HIShapeCreateMutableCopy(shape);
		HIShapeOffset(mutableShape, 0.0, shadowRadius);
		HIShapeReplacePathInCGContext(mutableShape, context);
		CGContextFillPath(context);
		CFRelease(mutableShape);

		CFRelease(shape);
	}

	HIThemeDrawWindowFrame(&contentRect, &windowDrawInfo, context, kHIThemeOrientationInverted, /*outTitleRect*/ NULL);

	NSRect titleRect = {
		{ 0.0, contentRect.size.height },
		titleSize
	};
	/*This doesn't actually work—the shape is empty.

	err = HIThemeGetWindowShape(&contentRect, &windowDrawInfo, kWindowTitleTextRgn, &shape);
	if (err == noErr) {
		HIShapeGetBounds(shape, &titleRect);
		NSLog(@"%@", NSStringFromRect(titleRect));

		CFRelease(shape);
	}
	 */
	struct HIThemeTextInfo titleTextInfo = {
		.version = 1,
		.state = kThemeStateActive,
		.fontID = kThemeWindowTitleFont,
		.horizontalFlushness = kHIThemeTextHorizontalFlushCenter,
		.verticalFlushness = kHIThemeTextVerticalFlushCenter,
		.options = kHIThemeTextBoxOptionEngraved,
		.truncationPosition = kHIThemeTextTruncationDefault,
		.truncationMaxLines = 1,
	};
	HIThemeDrawTextBox((__bridge CFTypeRef)(_title), &titleRect, &titleTextInfo, context, kHIThemeOrientationInverted);

	CGContextEndTransparencyLayer(context);
}

@end
