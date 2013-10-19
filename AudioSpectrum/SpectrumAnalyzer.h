#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "AudioInputBuffer.h"

@interface SpectrumAnalyzer : NSObject
{
@private
    NSUInteger _pointNumber;
    NSUInteger _logPointNumber;
    
    NSUInteger _bandType;
    
    FFTSetup _fftSetup;
    DSPSplitComplex _fftBuffer;
    Float32 *_window;

    Float32 *_spectrum;
    Float32 *_bandLevels;
}

@property (nonatomic, assign) NSUInteger pointNumber;
@property (nonatomic, assign) NSUInteger bandType;
@property (nonatomic, readonly) NSUInteger bandCount;
@property (nonatomic, readonly) const Float32 *spectrum;
@property (nonatomic, readonly) const Float32 *bandLevels;

- (void)calculateWithAudioInputBuffer:(AudioInputBuffer *)buffer;

+ (SpectrumAnalyzer *)sharedInstance;

@end
