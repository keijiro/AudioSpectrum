#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "AudioInputBuffer.h"

@interface SpectrumAnalyzer : NSObject
{
    NSUInteger pointNumber;
    NSUInteger logPointNumber;
    FFTSetup fftSetup;
    DSPSplitComplex fftBuffer;
    float* window;
    float* spectrum;
}

- (id)initWithPointNumber:(NSUInteger)number;
- (void)changePointNumber:(NSUInteger)number;

- (NSUInteger)pointNumber;
- (const float*)spectrum;

- (void)calculateWithAudioInputBuffer:(AudioInputBuffer *)buffer;

+ (id)sharedInstance;

@end
