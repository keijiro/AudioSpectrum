#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

@interface BandLevelView : NSView
{
    FFTSetup fftSetup;
    DSPSplitComplex fftBuffer;
    float* window;
}

@end
