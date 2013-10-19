#import "SpectrumView.h"
#import "SpectrumAnalyzer.h"
#import "AudioInputBuffer.h"

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
    
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);

    NSSize size = self.frame.size;

    // Draw the octave band graph.
    const float *bandLevels = [SpectrumAnalyzer sharedInstance].bandLevels;
    int bandCount = (int)[[SpectrumAnalyzer sharedInstance] countBands];
    
    float barInterval = size.width / bandCount;
    float barWidth = size.width / bandCount / 2;
    
    [[NSColor colorWithHue:0.3f saturation:0.4f brightness:0.8f alpha:1.0f] setFill];
    
    for (int i = 0; i < bandCount; i++) {
        float x = (0.5f + i)  * barInterval;
        float y = bandLevels[i] * 0.2f * size.height;
        NSRectFill(NSMakeRect(x - 0.5f * barWidth, 0, barWidth, y));
    }
    
    // Draw the spectrum graph.
    const float *spectra = [[SpectrumAnalyzer sharedInstance] spectra];
    int spectrumNumber = (int)[[SpectrumAnalyzer sharedInstance] pointNumber] / 2;

    NSBezierPath* spectrumPath = [NSBezierPath bezierPath];

    for (int i = 0; i < spectrumNumber; i++) {
        float x = log10f((float)i + 1) / log10f(spectrumNumber - 1) * size.width;
        float y = MIN(spectra[i] * 0.01f, 1.0f) * size.height;
        if (i == 0) {
            [spectrumPath moveToPoint:NSMakePoint(x, y)];
        } else {
            [spectrumPath lineToPoint:NSMakePoint(x, y)];
        }
    }
    
    [[NSColor blueColor] setStroke];
    [spectrumPath stroke];
    
    // Draw the input waveform graph.
    float waveform[spectrumNumber];
    [[AudioInputBuffer sharedInstance] copyTo:waveform length:spectrumNumber];

    NSBezierPath* path3 = [NSBezierPath bezierPath];
    [path3 moveToPoint:NSMakePoint(0, (waveform[0] * 0.5f + 0.5f) * size.height)];
    
    for (int i = 0; i < spectrumNumber; i += 2) {
        float x = (float)i * size.width / spectrumNumber;
        float y = (waveform[i] * 0.5f + 0.5f) * size.height;
        [path3 lineToPoint:NSMakePoint(x, y)];
    }
    [[NSColor grayColor] setStroke];
    
    [path3 stroke];

}

@end
