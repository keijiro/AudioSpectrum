#import "AudioInputBuffer.h"

#pragma mark Constants

#define kBufferTotal 16
#define kBufferStay 8
#define kBufferLength 256
#define kBufferByteLength (kBufferLength * sizeof(Float32))

#pragma mark Audio queue callback

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
    AudioInputBuffer* owner = (__bridge AudioInputBuffer *)(inUserData);
    [owner pushBuffer:inBuffer];
}

@implementation AudioInputBuffer

#pragma mark Construction and destruction

- (id)init
{
    self = [super init];
    if (self) {
        // 44.2 kHz single float LPCM
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
            AudioQueueAllocateBuffer(audioQueue, kBufferByteLength, &buffer);
            AudioQueueEnqueueBuffer(audioQueue, buffer, 0, NULL);
        }
        
        // Initialize the buffer array.
        lastBuffers = calloc(sizeof(AudioQueueBufferRef), kBufferStay);
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
    for (; count < kBufferStay && lastBuffers[count] != NULL; count++) {
    }
    
    if (count >= kBufferStay) {
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

    for (int i = 0; filled < length && i < kBufferStay && lastBuffers[i] != NULL; i++) {
        AudioQueueBufferRef buffer = lastBuffers[i];
        // Determine the length to copy.
        NSUInteger toCopy = MIN(length - filled, buffer->mAudioDataByteSize / sizeof(Float32));
        // Copy!
        memcpy(destination + filled, buffer->mAudioData, toCopy * sizeof(Float32));
        filled += toCopy;
    }
    
    // Not filled up?
    if (filled < length) {
        // Slide the waveform to the end of the buffer.
        NSUInteger rest = length - filled;
        memcpy(destination + rest, destination, filled * sizeof(Float32));
        memset(destination, 0, rest * sizeof(Float32));
    }
}

- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length
{
    NSUInteger filled = 0;
    
    for (int i = 0; filled * 2 < length && i < kBufferStay && lastBuffers[i] != NULL; i++) {
        AudioQueueBufferRef buffer = lastBuffers[i];
        const Float32 *data = buffer->mAudioData;
        NSAssert((buffer->mAudioDataByteSize & 1) == 0, @"Invalid data size.");
        // Determine the length to copy.
        NSUInteger toCopy = MIN(length - filled * 2, buffer->mAudioDataByteSize / sizeof(Float32));
        // Copy!
        for (int i = 0; i < toCopy; i += 2) {
            even[filled] = *data++;
            odd[filled] = *data++;
            filled++;
        }
    }
    
    // Not filled up?
    if (filled * 2 < length) {
        // Slide the waveform to the end of the buffer.
        NSUInteger rest = (length - filled * 2) / 2;
        memcpy(even + rest, even, filled * sizeof(Float32));
        memset(even, 0, rest * sizeof(Float32));
        memcpy(odd + rest, odd, filled * sizeof(Float32));
        memset(odd, 0, rest * sizeof(Float32));
    }
}

@end
