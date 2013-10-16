#import "SpectrumView.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fftSetup = vDSP_create_fftsetup(8, FFT_RADIX2); 
        fftBuffer.realp = malloc(256 * sizeof(float));
        fftBuffer.imagp = malloc(256 * sizeof(float));

        self.audioBuffer = [[AudioInputBuffer alloc] init];
        [self.audioBuffer start];

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

    float samples[256];
    NSUInteger sampleCount = [self.audioBuffer copyWaveformTo:samples length:256];
    
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, size.height * 0.5f)];

    for (int i = 0; i < sampleCount; i++) {
        float x = (float)i * size.width / sampleCount;
        float y = (samples[i] + 1.0f) * 0.5f * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    if (sampleCount > 0) [path stroke];
}

@end
