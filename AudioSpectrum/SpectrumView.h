#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

@interface SpectrumView : NSView
{
    FFTSetup fftSetup;
    DSPSplitComplex fftBuffer;
    float* window;
}

@end
