#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@class AudioInputBuffer;

@interface SpectrumAnalyzer : NSObject
{
@private
    // FFT data point number.
    NSUInteger _pointNumber;
    NSUInteger _logPointNumber;
    
    // Octave band type.
    NSUInteger _bandType;
    
    // FFT objects.
    FFTSetup _fftSetup;
    DSPSplitComplex _fftBuffer;
    Float32 *_window;

    // Spectrum data.
    Float32 *_spectrum;
    Float32 *_bandLevels;
}

// Configuration.
@property (nonatomic, assign) NSUInteger pointNumber;
@property (nonatomic, assign) NSUInteger bandType;

// Spectrum data accessors.
@property (nonatomic, readonly) const Float32 *spectrum;
@property (nonatomic, readonly) const Float32 *bandLevels;

// Returns the number of the octave bands.
- (NSUInteger)countBands;

// Process the audio input.
- (void)calculateWithAudioInputBuffer:(AudioInputBuffer *)buffer;

// Retrieve the shared instance.
+ (SpectrumAnalyzer *)sharedInstance;

@end
