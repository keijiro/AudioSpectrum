#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioInputBuffer : NSObject
{
@private
    AudioComponentInstance _auHAL;
    AudioBufferList *_inputBufferList;
    Float32 _sampleRate;
    Float32 *_ringBuffer;
    NSUInteger _ringBufferOffset;
}

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
