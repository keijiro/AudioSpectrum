#import "SpectrumAnalyzer.h"

@implementation SpectrumAnalyzer

#pragma mark Initialization

- (id)initWithPointNumber:(NSUInteger)number
{
    self = [super init];
    if (self) {
        [self changePointNumber:number];
    }
    return self;
}

- (void)dealloc
{
    [self changePointNumber:0];
}

- (void)changePointNumber:(NSUInteger)number
{
    // No need to update.
    if (pointNumber == number) return;
    
    // Free the objects if already initialized.
    if (pointNumber != 0) {
        vDSP_destroy_fftsetup(fftSetup);
        free(fftBuffer.realp);
        free(fftBuffer.imagp);
        free(window);
        free(spectrum);
    }

    // Update the number.
    pointNumber = number;
    logPointNumber = log2(number);
    
    if (number > 0) {
        // Allocate the objects and the arrays.
        fftSetup = vDSP_create_fftsetup(logPointNumber, FFT_RADIX2);
        
        fftBuffer.realp = calloc(pointNumber / 2, sizeof(float));
        fftBuffer.imagp = calloc(pointNumber / 2, sizeof(float));
        
        window = calloc(pointNumber, sizeof(float));
        vDSP_blkman_window(window, number, 0);
        
        spectrum = calloc(pointNumber / 2, sizeof(float));
    }
}

#pragma mark Accessor

- (NSUInteger)pointNumber
{
    return pointNumber;
}

- (const float*)spectrum
{
    return spectrum;
}

#pragma mark Convertion

- (void)calculateWithAudioInputBuffer:(AudioInputBuffer *)buffer
{
    [buffer splitEvenTo:fftBuffer.realp oddTo:fftBuffer.imagp totalLength:pointNumber];
    vDSP_vmul(fftBuffer.realp, 1, window, 2, fftBuffer.realp, 1, pointNumber / 2);
    vDSP_vmul(fftBuffer.imagp, 1, window + 1, 2, fftBuffer.imagp, 1, pointNumber / 2);
    vDSP_fft_zrip(fftSetup, &fftBuffer, 1, logPointNumber, FFT_FORWARD);
    vDSP_zvmags(&fftBuffer, 1, spectrum, 1, pointNumber / 2);
}

#pragma mark Static method

+ (id)sharedInstance
{
    static SpectrumAnalyzer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SpectrumAnalyzer alloc] initWithPointNumber:1024];
    });
    return instance;
}

@end
