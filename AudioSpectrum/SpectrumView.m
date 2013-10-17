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

    [self.audioBuffer splitEvenTo:fftBuffer.realp oddTo:fftBuffer.imagp totalLength:1024];
    
    vDSP_fft_zrip(fftSetup, &fftBuffer, 1, 10, FFT_FORWARD);

    float samples[512];
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
