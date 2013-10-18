#import "SpectrumView.h"
#import "SpectrumAnalyzer.h"

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    const float *spectrum = [[SpectrumAnalyzer sharedInstance] spectrum];
    int number = (int)[[SpectrumAnalyzer sharedInstance] pointNumber];
    
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];

    for (int i = 0; i < number / 2; i += 2) {
        float x = (float)i * size.width / (number / 2);
        float y = MIN(spectrum[i] * 0.5f, 1.0f) * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
