#import "SpectrumView.h"
#import <AudioToolbox/AudioToolbox.h>

static AudioQueueRef queue;
static AudioQueueBufferRef buffers[4];

static float waveform[512];

static void HandleInputBuffer(void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
    const float *samples = (const float *)inBuffer->mAudioData;
    for (int i = 0; i < 512 && i < inNumPackets; i++) {
        waveform[i] = samples[i];
    }
    
    AudioQueueEnqueueBuffer(queue, inBuffer, 0, nil);
}

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        AudioStreamBasicDescription inFormat = {0};
        inFormat.mFormatID = kAudioFormatLinearPCM;
        inFormat.mSampleRate = 44100;
        inFormat.mChannelsPerFrame = 1;
        inFormat.mBitsPerChannel = 32;
        inFormat.mBytesPerPacket = inFormat.mBytesPerFrame = inFormat.mChannelsPerFrame * sizeof(AudioSampleType);
        inFormat.mFramesPerPacket = 1;
        inFormat.mFormatFlags = kAudioFormatFlagsCanonical;
        
        AudioQueueNewInput(&inFormat, HandleInputBuffer, nil, nil, kCFRunLoopCommonModes, 0, &queue);
        
        for (int i = 0; i < 4; i++) {
            AudioQueueAllocateBuffer(queue, 1024, &buffers[i]);
            AudioQueueEnqueueBuffer(queue, buffers[i], 0, nil);
        }
        
        AudioQueueStart(queue, nil);
        
        [NSTimer scheduledTimerWithTimeInterval:(1.0f / 100) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)redraw
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    NSSize size = self.frame.size;
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, size.height * 0.5f)];
    for (int i = 0; i < 512; i++) {
        float x = (float)i * size.width / 512;
        float y = (waveform[i] + 1.0f) * 0.5f * size.height;
        [path lineToPoint:NSMakePoint(x, y)];
    }
    
    [path stroke];
}

@end
