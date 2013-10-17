#import "SpectrumView.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fftSetup = vDSP_create_fftsetup(10, FFT_RADIX2);
        fftBuffer.realp = malloc(512 * sizeof(float));
        fftBuffer.imagp = malloc(512 * sizeof(float));

        self.audioBuffer = [[AudioInputBuffer alloc] init];
        [self.audioBuffer start];

        [NSTimer scheduledTimerWithTimeInterval:(1.0f / 60) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
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

    float samples[1024];
    NSUInteger sampleCount = [self.audioBuffer copyWaveformTo:samples length:1024];
    
    if (sampleCount != 1024) return;
    
    vDSP_ctoz((DSPComplex*)samples, 2, &fftBuffer, 1, 512);
    
    vDSP_fft_zrip(fftSetup, &fftBuffer, 1, 10, FFT_FORWARD);
    
    for (int i = 0; i < 512; i++) {
        samples[i] = sqrtf(fftBuffer.realp[i] * fftBuffer.realp[i] + fftBuffer.imagp[i] * fftBuffer.imagp[i]);
    }
    
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];

    for (int i = 0; i < 512; i++) {
        float x = (float)i * size.width / 512;
        float y = samples[i] * 0.5f * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
