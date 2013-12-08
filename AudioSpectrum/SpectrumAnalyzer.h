// Realtime FFT spectrum and octave-band analysis.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@class AudioInputHandler;

@interface SpectrumAnalyzer : NSObject

// Configuration.
@property (nonatomic, assign) NSUInteger pointNumber;
@property (nonatomic, assign) NSUInteger bandType;

// Spectrum data accessors.
@property (nonatomic, readonly) const Float32 *spectrum;
@property (nonatomic, readonly) const Float32 *bandLevels;

// Returns the number of the octave bands.
- (NSUInteger)countBands;

// Process the audio input.
- (void)calculateWithAudioInput:(AudioInputHandler *)handler;

// Retrieve the shared instance.
+ (SpectrumAnalyzer *)sharedInstance;

@end
