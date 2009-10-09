#import "ProgressCell.h"

@implementation ProgressCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame.size.height -= 1.0;														// adjust height for better look
	[super drawWithFrame:cellFrame inView:controlView];
	if ([self floatValue] >= 100.0)
		return;
	
	// set center alignment
	NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setAlignment:NSCenterTextAlignment];

	// set text font
	NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:[self controlSize]]];
	
	// collect text attributes
	NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 style, NSParagraphStyleAttributeName,
								 font, NSFontAttributeName, nil];
	
	// making the text and draw it
	NSString *data = [NSString stringWithFormat:@"%.2f%%", [self floatValue]];
	[data drawInRect:cellFrame withAttributes:attr];
}

@end
