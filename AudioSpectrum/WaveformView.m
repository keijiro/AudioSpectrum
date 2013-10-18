#import "WaveformView.h"
#import "AudioInputBuffer.h"

@implementation WaveformView

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
    
    float waveform[512];
    [[AudioInputBuffer sharedInstance] copyTo:waveform length:512];
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, (waveform[0] * 0.5f + 0.5f) * size.height)];
    
    for (int i = 0; i < 512; i += 2) {
        float x = (float)i * size.width / 512;
        float y = (waveform[i] * 0.5f + 0.5f) * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
