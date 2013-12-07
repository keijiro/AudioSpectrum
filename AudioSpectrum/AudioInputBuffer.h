// Provides a low-latency audio input buffer with the system default device.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioInputBuffer : NSObject

// Sampling rate.
@property (readonly) Float32 sampleRate;

// Control methods.
- (void)start;
- (void)stop;

// Waveform retrieval methods.
- (void)copyTo:(Float32 *)destination length:(NSUInteger)length;
- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length;

// Retrieve the shared instance.
+ (AudioInputBuffer *)sharedInstance;

@end
