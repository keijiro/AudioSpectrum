#import "BandLevelView.h"
#import "SpectrumAnalyzer.h"

@implementation BandLevelView

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
    
    const float *bandLevels = [SpectrumAnalyzer sharedInstance].bandLevels;
    int bandCount = (int)[SpectrumAnalyzer sharedInstance].bandCount;
    
        NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];
    
    for (int i = 0; i < bandCount; i++) {
        float x = (float)i * size.width / bandCount;
        float y = bandLevels[i] * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
