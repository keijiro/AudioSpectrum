// Provides a low-latency audio input buffer with the system default device.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@class AudioRingBuffer;

@interface AudioInputBuffer : NSObject

// Sampling rate.
@property (readonly) Float32 sampleRate;

// Ring buffer.
@property (readonly) AudioRingBuffer *ringBuffer;

// Control methods.
- (void)start;
- (void)stop;

// Retrieve the shared instance.
+ (AudioInputBuffer *)sharedInstance;

@end
