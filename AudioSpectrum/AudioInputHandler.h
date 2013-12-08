// Handles audio input from the system default device.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioInputHandler : NSObject

// Sampling rate.
@property (readonly) Float32 sampleRate;

// Ring buffer array.
@property (readonly) NSArray *ringBuffers;

// Control methods.
- (void)start;
- (void)stop;

// Retrieve the shared instance.
+ (AudioInputHandler *)sharedInstance;

@end
