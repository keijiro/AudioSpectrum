#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>
#import "AudioInputBuffer.h"

@interface SpectrumView : NSView
{
    FFTSetup fftSetup;
    DSPSplitComplex fftBuffer;
}

@property(strong) AudioInputBuffer *audioBuffer;

@end
