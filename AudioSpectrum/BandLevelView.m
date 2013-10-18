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
    
    const float *spectrum = [[SpectrumAnalyzer sharedInstance] spectrum];
    int number = (int)[[SpectrumAnalyzer sharedInstance] pointNumber];
    
    float middleFreqs[] = { 31.5f, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 };
    float bandWidth = 1.414f;
    
    float levels[10];
    for (int band = 0; band < 10; band++) {
        int sidxLo = floorf(middleFreqs[band] / bandWidth / 44100 * number);
        int sidxHi = floorf(middleFreqs[band] * bandWidth / 44100 * number);
        
        sidxLo = MIN(MAX(sidxLo, 0), number / 2 - 1);
        sidxHi = MIN(MAX(sidxLo, 0), number / 2 - 1);
        
        float max = 0.0f;
        for (int i = sidxLo; i <= sidxHi; i++) {
            max = MAX(max, spectrum[i]);
        }
        
        levels[band] = max;
    }
    
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];
    
    for (int i = 0; i < 10; i++) {
        float x = (float)i * size.width / 10;
        float y = levels[i] * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
