#import "SpectrumView.h"

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [NSTimer scheduledTimerWithTimeInterval:(1.0f / 20) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)redraw
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    NSSize size = self.frame.size;
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];
    for (int i = 0; i < 128; i++) {
        float x = (float)i * size.width / 128;
        float y = arc4random() % (int)size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
