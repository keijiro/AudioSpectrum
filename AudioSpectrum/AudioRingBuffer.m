#import <Accelerate/Accelerate.h>
#import "AudioRingBuffer.h"

#pragma mark Configurations

#define kBufferSize (1024 * 16)
#define kBufferByteSize (kBufferSize * sizeof(Float32))

#pragma mark Local utility function

static inline void FloatCopy(const Float32 *source, Float32 *destination, NSUInteger length)
{
    memcpy(destination, source, length * sizeof(Float32));
}

#pragma mark Private method definition

@interface AudioRingBuffer ()
{
@private
    Float32 *_samples;
    NSUInteger _offset;
}
@end

#pragma mark

@implementation AudioRingBuffer

#pragma mark Constructor / destructor

- (id)init
{
    self = [super init];
    if (self) {
        _samples = malloc(kBufferByteSize);
        memset(_samples, 0, kBufferByteSize);
    }
    return self;
}

- (void)dealloc
{
    free(_samples);
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark Buffer operations

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length
{
    // Take a snapshot of the current status for avoiding race conditions.
    NSUInteger offset = _offset;
    
    // We don't care if the status is going to be changed, because there is enough margin.
    
    if (length <= offset) {
        // Simply copy a part of the ring buffer.
        FloatCopy(_samples + offset - length, destination, length);
    } else {
        // Copy the tail and the head of the ring buffer.
        NSUInteger tail = length - offset;
        FloatCopy(_samples + kBufferSize - tail, destination, tail);
        FloatCopy(_samples, destination + tail, offset);
    }
}

- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length
{
    // Take a snapshot of the current status for avoiding race conditions.
    NSUInteger offset = _offset;
    
    // We don't care if the status is going to be changed, because there is enough margin.
    
    if (length <= offset) {
        // Simply copy a part of the ring buffer.
        DSPSplitComplex dest = { even, odd };
        vDSP_ctoz((const DSPComplex*)(_samples + offset - length), 2, &dest, 1, length / 2);
    } else {
        // Copy the tail and the head of the ring buffer.
        NSUInteger tail = length - offset;
        DSPSplitComplex destTail = { even, odd };
        DSPSplitComplex destHead = { even + tail / 2, odd + tail / 2 };
        vDSP_ctoz((const DSPComplex*)(_samples + kBufferSize - tail), 2, &destTail, 1, tail / 2);
        vDSP_ctoz((const DSPComplex*)_samples, 2, &destHead, 1, offset / 2);
    }
}

- (void)pushSamples:(Float32 *)source count:(NSUInteger)count
{
    NSUInteger rest = kBufferSize - _offset;
    if (count <= rest) {
        // Simply copy the input data.
        FloatCopy(source, _samples + _offset, count);
        _offset += count;
    } else {
        // Split the input data into two parts and copy the each part.
        FloatCopy(source, _samples + _offset, rest);
        FloatCopy(source + rest, _samples, count - rest);
        _offset = count - rest;
    }
}

@end
