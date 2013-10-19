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
    
    [[NSColor blueColor] setStroke];
    [path stroke];


    const float *bandLevels = [SpectrumAnalyzer sharedInstance].bandLevels;
    int bandCount = (int)[SpectrumAnalyzer sharedInstance].bandCount;
    
    NSBezierPath* path2 = [NSBezierPath bezierPath];
    [path2 moveToPoint:NSMakePoint(0, 0)];
    
    for (int i = 0; i < bandCount; i++) {
        float x = (float)i * size.width / bandCount;
        float y = bandLevels[i] * size.height;
        [path2 lineToPoint:NSMakePoint(x, y)];
    }
    
    [[NSColor redColor] setStroke];
    [path2 stroke];


    float waveform[512];
    [[AudioInputBuffer sharedInstance] copyTo:waveform length:512];
    NSBezierPath* path3 = [NSBezierPath bezierPath];
    [path3 moveToPoint:NSMakePoint(0, (waveform[0] * 0.5f + 0.5f) * size.height)];
    
    for (int i = 0; i < 512; i += 2) {
        float x = (float)i * size.width / 512;
        float y = (waveform[i] * 0.5f + 0.5f) * size.height;
        [path3 lineToPoint:NSMakePoint(x, y)];
    }
    [[NSColor grayColor] setStroke];
    
    [path3 stroke];

}

@end
