#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioInputBuffer : NSObject
{
    AudioQueueRef audioQueue;
    AudioQueueBufferRef *lastBuffers;
}

- (void)start;
- (void)stop;
- (void)pushBuffer:(AudioQueueBufferRef)buffer;
- (void)copyTo:(Float32 *)destination length:(NSUInteger)length;
- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length;

+ (AudioInputBuffer *)sharedInstance;

@end
