// Custom view for displaying a spectrum.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import "SpectrumView.h"
#import "SpectrumAnalyzer.h"
#import "AudioInputHandler.h"
#import "AudioRingBuffer.h"

@interface SpectrumView ()
{
    IBOutlet SpectrumAnalyzer *_analyzer;
}
@end

#pragma mark Local functions

#define MIN_DB (-60.0f)

static float ConvertLogScale(float x)
{
    return -log10f(0.1f + x / (MIN_DB * 1.1f));
}

#pragma mark Class implementation

@implementation SpectrumView

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    NSSize size = self.frame.size;
    
    // Clear the rect.
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    
    // Update the spectrum.
    AudioInputHandler *audioInput = [AudioInputHandler sharedInstance];
    [_analyzer processAudioInput:audioInput];
    
    // Draw horizontal lines.
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        
        for (float lv = -3.0f; lv > MIN_DB; lv -= 3.0f) {
            float y = ConvertLogScale(lv) * size.height;
            [path moveToPoint:NSMakePoint(0, y)];
            [path lineToPoint:NSMakePoint(size.width, y)];
        }
        
        [[NSColor colorWithWhite:0.5f alpha:1.0f] setStroke];
        [path setLineWidth:0.5f];
        [path stroke];
    }
    
    // Draw the input waveform graph.
    {
        int waveformLength = (int)_analyzer.pointNumber;
        float waveform[waveformLength];
        [audioInput.ringBuffers.firstObject copyTo:waveform length:waveformLength];
        
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
        
        [[NSColor colorWithWhite:0.5f alpha:1.0f] setStroke];
        [path setLineWidth:0.5f];
        [path stroke];
    }
    
    // Draw the level meter.
    {
        float zeroOffset = 1.5849e-13;
        float refLevel = 0.70710678118f; // 1/sqrt(2)

        NSColor *red = [NSColor colorWithHue:0.0f saturation:0.8f brightness:1.0f alpha:1.0f];
        NSColor *yellow = [NSColor colorWithHue:0.12f saturation:0.8f brightness:1.0f alpha:1.0f];
        NSColor *green = [NSColor colorWithHue:0.4f saturation:0.8f brightness:1.0f alpha:1.0f];
        
        int sampleCount = audioInput.sampleRate / 60; // 60 fps
        NSUInteger channels = audioInput.ringBuffers.count;
        
        for (int i = 0; i < channels; i++)
        {
            float rms = [audioInput.ringBuffers[i] calculateRMS:sampleCount];
            float db = 20.0f * log10f(rms / refLevel + zeroOffset);
            float y = ConvertLogScale(db) * size.height;

            if (db >= 0.0f) {
                [red setFill];
            } else if (db > -3.0f) {
                [yellow setFill];
            } else {
                [green setFill];
            }
            
            NSRectFill(NSMakeRect((0.5f + i) * size.width / channels, 0, 12, y));
        }
    }

    // Draw the octave band graph.
    {
        const float *bandLevels = _analyzer.bandLevels;
        int bandCount = (int)[_analyzer countBands];
        
        float barInterval = size.width / bandCount;
        float barWidth = 0.5f * barInterval;
        
        [[NSColor colorWithWhite:0.8f alpha:1.0f] setFill];
        
        for (int i = 0; i < bandCount; i++) {
            float x = (0.5f + i)  * barInterval;
            float y = ConvertLogScale(bandLevels[i]) * size.height;
            NSRectFill(NSMakeRect(x - 0.5f * barWidth, 0, barWidth, y));
        }
    }
    
    // Draw the spectrum graph.
    {
        const float *spectrum = _analyzer.spectrum;
        int spectrumCount = (int)_analyzer.pointNumber / 2;
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        float xScale = size.width / log10f(spectrumCount - 1);

        for (int i = 1; i < spectrumCount; i++) {
            float x = log10f(i) * xScale;
            float y = ConvertLogScale(spectrum[i]) * size.height;
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
}

@end
