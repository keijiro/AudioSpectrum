#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioInputBuffer : NSObject
{
@private
    // Audio queue objects.
    AudioQueueRef audioQueue;
    AudioQueueBufferRef *lastBuffers;
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
