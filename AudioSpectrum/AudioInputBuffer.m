#import <Accelerate/Accelerate.h>
#import "AudioInputBuffer.h"

#define kBufferTotal 64
#define kBufferStay 32
#define kBufferLength 128

#pragma mark Audio queue callback

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
    AudioInputBuffer* owner = (__bridge AudioInputBuffer *)(inUserData);
    [owner pushBuffer:inBuffer];
}

#pragma mark

@implementation AudioInputBuffer

#pragma mark Construction and destruction

- (id)init
{
    self = [super init];
    if (self) {
        // 44.1 kHz single float LPCM
        AudioStreamBasicDescription format = {0};
        format.mFormatID = kAudioFormatLinearPCM;
        format.mSampleRate = 44100;
        format.mChannelsPerFrame = 1;
        format.mBitsPerChannel = 32;
        format.mBytesPerPacket = format.mChannelsPerFrame * sizeof(Float32);
        format.mBytesPerFrame = format.mBytesPerPacket;
        format.mFramesPerPacket = 1;
        format.mFormatFlags = kAudioFormatFlagsCanonical;
        
        // Initialize the audio queue object.
        AudioQueueNewInput(&format, HandleInputBuffer, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0, &audioQueue);
        
        // Initialize the buffers.
        for (int i = 0; i < kBufferTotal; i++) {
            AudioQueueBufferRef buffer;
            AudioQueueAllocateBuffer(audioQueue, kBufferLength * sizeof(Float32), &buffer);
            AudioQueueEnqueueBuffer(audioQueue, buffer, 0, NULL);
        }
        
        // Initialize the buffer array.
        lastBuffers = calloc(sizeof(AudioQueueBufferRef), kBufferStay + 1);
    }
    return self;
}

- (void)dealloc
{
    AudioQueueDispose(audioQueue, false);
    // The buffers are disposed with the queue.
}

#pragma mark Start and stop

- (void)start
{
    AudioQueueStart(audioQueue, NULL);
}

- (void)stop
{
    AudioQueueStop(audioQueue, false);
}

#pragma mark Buffer operations

- (void)pushBuffer:(AudioQueueBufferRef)buffer
{
    // Count the buffers already in the array.
    int count = 0;
    while (lastBuffers[count] != NULL) { // Always stops at the sentinel.
        count++;
    }
    
    if (count == kBufferStay) {
        // Re-enqueue the first buffer and remove it from the array.
        AudioQueueEnqueueBuffer(audioQueue, lastBuffers[0], 0, NULL);
        for (int i = 0; i < count - 1; i++) {
            lastBuffers[i] = lastBuffers[i + 1];
        }
        count--;
    }

    // Append the buffer to the array.
    lastBuffers[count] = buffer;
}

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length
{
    NSUInteger filled = 0;
    int bufferIndex = 0;
    
    while (filled < length) {
        // Get the next buffer.
        AudioQueueBufferRef buffer = lastBuffers[bufferIndex++];
        if (buffer == NULL) break; // Stops at the sentinel.
        
        // Determine the length to copy.
        NSUInteger toCopy = MIN(length - filled, buffer->mAudioDataByteSize / sizeof(Float32));
        
        // Copy!
        memcpy(destination + filled, buffer->mAudioData, toCopy * sizeof(Float32));
        filled += toCopy;
    }
    
    // Not filled up?
    if (filled < length) {
        // Slide the waveform to the end of the buffer.
        NSUInteger offset = length - filled;
        memcpy(destination + offset, destination, filled * sizeof(Float32));
        memset(destination, 0, offset * sizeof(Float32));
    }
}

- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length
{
    // Use half number of the length.
    NSAssert((length & 1) == 0, @"Invalid arguments (totalLength must be even number)");
    length /= 2;
    
    NSUInteger filled = 0;
    int bufferIndex = 0;

    while (filled < length) {
        // Get the next buffer.
        AudioQueueBufferRef buffer = lastBuffers[bufferIndex++];
        if (buffer == NULL) break; // Always stops at the sentinel.
        
        NSAssert((buffer->mAudioDataByteSize & 1) == 0, @"Invalid data size (must be even number)");

        // Determine the length to copy.
        NSUInteger toCopy = MIN(length - filled, buffer->mAudioDataByteSize / (2 * sizeof(Float32)));

        // Copy!
        DSPSplitComplex tempComplex = { even + filled, odd + filled };
        vDSP_ctoz((const DSPComplex*)buffer->mAudioData, 2, &tempComplex, 1, toCopy);
        filled += toCopy;
    }

    // Not filled up?
    if (filled < length) {
        // Slide the waveform to the end of the buffer.
        NSUInteger offset = length - filled;
        
        DSPSplitComplex c1 = { even, odd };
        DSPSplitComplex c2 = { even + offset, odd + offset };
        
        vDSP_zvmov(&c1, 1, &c2, 1, filled / 2);
        
        vDSP_vclr(c1.realp, 1, offset);
        vDSP_vclr(c1.imagp, 1, offset);
    }
}

#pragma mark Static method

+ (AudioInputBuffer *)sharedInstance
{
    static AudioInputBuffer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioInputBuffer alloc] init];
    });
    return instance;
}

@end
