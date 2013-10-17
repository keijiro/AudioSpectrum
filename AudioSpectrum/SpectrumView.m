#import "SpectrumView.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fftSetup = vDSP_create_fftsetup(12, FFT_RADIX2);
        fftBuffer.realp = malloc(512 * sizeof(float));
        fftBuffer.imagp = malloc(512 * sizeof(float));

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

    [self.audioBuffer splitEvenTo:fftBuffer.realp oddTo:fftBuffer.imagp totalLength:1024];
    vDSP_fft_zrip(fftSetup, &fftBuffer, 1, 10, FFT_FORWARD);

    float spectrum[512];
    vDSP_zvmags(&fftBuffer, 1, spectrum, 1, 512);
    
    NSSize size = self.frame.size;
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];

    for (int i = 0; i < 512; i += 2) {
        float x = (float)i * size.width / 512;
        float y = MIN(spectrum[i] * 0.5f, 1.0f) * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
