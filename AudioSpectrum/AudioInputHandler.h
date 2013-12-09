// Handles audio input from the system default device.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioInputHandler : NSObject
{
@private
    AudioComponentInstance _auHAL;
    AudioBufferList *_inputBufferList;
    NSArray *_ringBuffers;
    Float32 _sampleRate;
}

// Sampling rate.
@property (nonatomic, readonly) Float32 sampleRate;

// Ring buffer array.
@property (nonatomic, readonly) NSArray *ringBuffers;

// Control methods.
- (void)start;
- (void)stop;

// Retrieve the shared instance.
+ (AudioInputHandler *)sharedInstance;

@end
