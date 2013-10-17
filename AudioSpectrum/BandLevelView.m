#import "BandLevelView.h"
#import "AudioInputBuffer.h"

@implementation BandLevelView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fftSetup = vDSP_create_fftsetup(12, FFT_RADIX2);
        fftBuffer.realp = malloc(512 * sizeof(float));
        fftBuffer.imagp = malloc(512 * sizeof(float));
        
        window = calloc(1024, sizeof(float));
        vDSP_blkman_window(window, 1024, 0);
        
        [NSTimer scheduledTimerWithTimeInterval:(1.0f / 30) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
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
    
    [[AudioInputBuffer sharedInstance] splitEvenTo:fftBuffer.realp oddTo:fftBuffer.imagp totalLength:1024];
    vDSP_vmul(fftBuffer.realp, 1, window, 2, fftBuffer.realp, 1, 512);
    vDSP_vmul(fftBuffer.imagp, 1, window + 1, 2, fftBuffer.imagp, 1, 512);
    vDSP_fft_zrip(fftSetup, &fftBuffer, 1, 10, FFT_FORWARD);
    
    float spectrum[512];
    vDSP_zvmags(&fftBuffer, 1, spectrum, 1, 512);
    
    float middleFreqs[] = { 31.5f, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 };
    float bandWidth = 1.414f;
    
    float levels[10];
    for (int band = 0; band < 10; band++) {
        int sidxLo = floorf(middleFreqs[band] / bandWidth / 44100 * 2 * 512);
        int sidxHi = floorf(middleFreqs[band] * bandWidth / 44100 * 2 * 512);
        
        sidxLo = MIN(MAX(sidxLo, 0), 511);
        sidxHi = MIN(MAX(sidxLo, 0), 511);
        
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
