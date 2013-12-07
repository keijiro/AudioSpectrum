// Custom view for displaying a spectrum.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import "SpectrumView.h"
#import "SpectrumAnalyzer.h"
#import "AudioInputBuffer.h"
#import "AudioRingBuffer.h"

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

    NSSize size = self.frame.size;
    
    // Clear the rect.
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    
    // Update the spectrum.
    SpectrumAnalyzer *analyzer = [SpectrumAnalyzer sharedInstance];
    [analyzer calculateWithAudioInputBuffer:[AudioInputBuffer sharedInstance]];

    // Draw the octave band graph.
    {
        const float *bandLevels = analyzer.bandLevels;
        int bandCount = (int)[analyzer countBands];
        
        float barInterval = size.width / bandCount;
        float barWidth = 0.5f * barInterval;
        
        [[NSColor colorWithWhite:0.8f alpha:1.0f] setFill];
        
        for (int i = 0; i < bandCount; i++) {
            float x = (0.5f + i)  * barInterval;
            float y = (1.0f + 0.01f * bandLevels[i]) * size.height;
            NSRectFill(NSMakeRect(x - 0.5f * barWidth, 0, barWidth, y));
        }
    }
    
    // Draw the spectrum graph.
    {
        const float *spectrum = analyzer.spectrum;
        int spectrumCount = (int)analyzer.pointNumber / 2;
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / log10f(spectrumCount - 1);

        for (int i = 1; i < spectrumCount; i++) {
            float x = log10f(i) * xScale;
            float y = (1.0f + 0.01f * spectrum[i]) * size.height;
            if (i == 1) {
                [path moveToPoint:NSMakePoint(x, y)];
            } else {
                [path lineToPoint:NSMakePoint(x, y)];
            }
        }
        
        [[NSColor blueColor] setStroke];
        [path setLineWidth:0.5f];
        [path stroke];
    }
    
    // Draw the input waveform graph.
    {
        int waveformLength = (int)analyzer.pointNumber;
        float waveform[waveformLength];
        [[AudioInputBuffer sharedInstance].ringBuffers.firstObject copyTo:waveform length:waveformLength];
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / waveformLength;
        
        for (int i = 0; i < waveformLength; i++) {
            float x = xScale * i;
            float y = (waveform[i] * 0.5f + 0.5f) * size.height;
            if (i == 0) {
                [path moveToPoint:NSMakePoint(x, y)];
            } else {
                [path lineToPoint:NSMakePoint(x, y)];
            }
        }
        
        [[NSColor blackColor] setStroke];
        [path setLineWidth:0.5f];
        [path stroke];
    }
}

@end
