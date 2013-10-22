#import "AudioInputBuffer.h"
#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudio.h>

#pragma mark Configurations

#define kRingBufferSize 4096
#define kRingBufferByteSize (kRingBufferSize * sizeof(Float32))

#pragma mark Private method definition

@interface AudioInputBuffer(PrivateMethod)
- (void)initAudioUnit;
- (void)inputCallback:(AudioUnitRenderActionFlags *)ioActionFlags
          inTimeStamp:(const AudioTimeStamp *)inTimeStamp
          inBusNumber:(UInt32)inBusNumber
        inNumberFrame:(UInt32)inNumberFrame;
@end

#pragma mark Audio unit callback

static OSStatus InputRenderProc(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrame,
                            AudioBufferList *ioData)
{
    AudioInputBuffer* owner = (__bridge AudioInputBuffer *)(inRefCon);
    [owner inputCallback:ioActionFlags inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrame:inNumberFrame];
    return noErr;
}

#pragma mark

@implementation AudioInputBuffer

#pragma mark Constructor / destructor

- (id)init
{
    self = [super init];
    if (self) {
        [self initAudioUnit];
        _ringBuffer = malloc(kRingBufferByteSize);
        memset(_ringBuffer, 0, kRingBufferByteSize);
    }
    return self;
}

- (void)dealloc
{
    free(_ringBuffer);
}

#pragma mark Accessor

- (Float32)sampleRate
{
    return _sampleRate;
}

#pragma mark Control methods

- (void)start
{
    OSStatus error = AudioOutputUnitStart(_auHAL);
    NSAssert(error == noErr, @"Failed to start the AUHAL (%d).", error);
}

- (void)stop
{
    AudioOutputUnitStop(_auHAL);
}

#pragma mark Waveform retrieval methods

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length
{
    NSUInteger byteLength = length * sizeof(Float32);
    if (byteLength <= _ringBufferOffset) {
        memcpy(destination, _ringBuffer + _ringBufferOffset - byteLength, byteLength);
    } else {
        NSUInteger fragSize = byteLength - _ringBufferOffset;
        memcpy(destination, _ringBuffer + kRingBufferByteSize - fragSize, fragSize);
        memcpy((void*)destination + fragSize, _ringBuffer, _ringBufferOffset);
    }
}

- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length
{
    NSUInteger byteLength = length * sizeof(Float32);
    if (byteLength <= _ringBufferOffset) {
        DSPSplitComplex tempComplex = { even, odd };
        vDSP_ctoz((const DSPComplex*)_ringBuffer, 2, &tempComplex, 1, length / 2);
    } else {
        NSUInteger fragSize = byteLength - _ringBufferOffset;
        NSUInteger fragSize2 = (byteLength - _ringBufferOffset) / sizeof(float);
        DSPSplitComplex tempComplex1 = { even, odd };
        DSPSplitComplex tempComplex2 = { even + fragSize2 / 2, odd + fragSize2 / 2 };
        vDSP_ctoz((const DSPComplex*)((void*)_ringBuffer  + kRingBufferByteSize - fragSize), 2, &tempComplex1, 1, fragSize2 / 2);
        vDSP_ctoz((const DSPComplex*)_ringBuffer, 2, &tempComplex2, 1, _ringBufferOffset / sizeof(float) / 2);
    }
}

#pragma mark Private method

- (void)initAudioUnit
{
    //
    // Create an AUHAL instance.
    //
    
    AudioComponent component;
    AudioComponentDescription description;
    
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_HALOutput;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;
    
    component = AudioComponentFindNext(NULL, &description);
    NSAssert(component, @"Failed to find an input device.");
    
    OSStatus error = AudioComponentInstanceNew(component, &_auHAL);
    NSAssert(error == noErr, @"Failed to create an AUHAL instance.");
    
    //
    // Enable the input bus, and disable the output bus.
    //
    
    const UInt32 kInputElement = 1;
    const UInt32 kOutputElement = 0;

    UInt32 enableIO = 1;
    error = AudioUnitSetProperty(_auHAL,
                                 kAudioOutputUnitProperty_EnableIO,
                                 kAudioUnitScope_Input,
                                 kInputElement,
                                 &enableIO,
                                 sizeof(enableIO));
    NSAssert(error == noErr, @"Failed to enable the input bus.");
    
    enableIO = 0;
    error = AudioUnitSetProperty(_auHAL,
                                 kAudioOutputUnitProperty_EnableIO,
                                 kAudioUnitScope_Output,
                                 kOutputElement,
                                 &enableIO,
                                 sizeof(enableIO));
    NSAssert(error == noErr, @"Failed to disable the output bus.");
    
    //
    // Set the unit to the default input device.
    //
    
    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    AudioDeviceID inputDevice;
    UInt32 size = sizeof(AudioDeviceID);
    
    error = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                       &address,
                                       0,
                                       NULL,
                                       &size,
                                       &inputDevice);
    NSAssert(error == noErr, @"Failed to retrieve the default input device.");

    error = AudioUnitSetProperty(_auHAL,
                                 kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global,
                                 0,
                                 &inputDevice,
                                 sizeof(inputDevice));
    NSAssert(error == noErr, @"Failed to set the unit to the default input device.");
    
    //
    // Adopt the stream format.
    //
    
    AudioStreamBasicDescription deviceFormat;
    AudioStreamBasicDescription desiredFormat;
    size = sizeof(AudioStreamBasicDescription);
    
    error = AudioUnitGetProperty(_auHAL,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Input,
                                 kInputElement,
                                 &deviceFormat,
                                 &size);
    NSAssert(error == noErr, @"Failed to get the input format.");

    error = AudioUnitGetProperty(_auHAL,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output,
                                 kInputElement,
                                 &desiredFormat,
                                 &size);
    NSAssert(error == noErr, @"Failed to get the output format.");
    
    // Same sample rate, same number of channels.
    desiredFormat.mSampleRate = deviceFormat.mSampleRate;
    desiredFormat.mChannelsPerFrame = deviceFormat.mChannelsPerFrame;
    
    // Canonical audio format.
    desiredFormat.mFormatID = kAudioFormatLinearPCM;
    desiredFormat.mFormatFlags = kAudioFormatFlagsAudioUnitCanonical;
    desiredFormat.mFramesPerPacket = 1;
    desiredFormat.mBytesPerFrame = sizeof(Float32);
    desiredFormat.mBytesPerPacket = sizeof(Float32);
    desiredFormat.mBitsPerChannel = 8 * sizeof(Float32);
    
    error = AudioUnitSetProperty(_auHAL,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output,
                                 kInputElement,
                                 &desiredFormat,
                                 sizeof(AudioStreamBasicDescription));
    NSAssert(error == noErr, @"Failed to set the output format.");
    
    // Store the format info.
    _sampleRate = deviceFormat.mSampleRate;
    _channels = deviceFormat.mChannelsPerFrame;
    
    //
    // Get the buffer frame size.
    //
    
    UInt32 bufferSizeFrames;
    size = sizeof(UInt32);
    
    error = AudioUnitGetProperty(_auHAL,
                                 kAudioDevicePropertyBufferFrameSize,
                                 kAudioUnitScope_Global,
                                 0,
                                 &bufferSizeFrames,
                                 &size);
    NSAssert(error == noErr, @"Failed to get the buffer frame size.");
    
    //
    // Allocate the buffer.
    //
    
    UInt32 bufferSizeBytes = bufferSizeFrames * sizeof(Float32);
    
    _inputBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * _channels);
    _inputBufferList->mNumberBuffers = _channels;
    
    for (UInt32 i = 0; i < _channels; i++) {
        AudioBuffer *buffer = &_inputBufferList->mBuffers[i];
        buffer->mNumberChannels = 1;
        buffer->mDataByteSize = bufferSizeBytes;
        buffer->mData = malloc(bufferSizeBytes);
    }
    
    //
    // Set up the input callback.
    //
    
    AURenderCallbackStruct cb = { InputRenderProc, (__bridge void *)(self) };
    
    error = AudioUnitSetProperty(_auHAL,
                                 kAudioOutputUnitProperty_SetInputCallback,
                                 kAudioUnitScope_Global,
                                 0,
                                 &cb,
                                 sizeof(AURenderCallbackStruct));
    NSAssert(error == noErr, @"Failed to set up the input callback.");
    
    //
    // Complete the initialization.
    //
    
    error = AudioUnitInitialize(_auHAL);
    NSAssert(error == noErr, @"Failed to initialize the AUHAL.");
}

- (void)inputCallback:(AudioUnitRenderActionFlags *)ioActionFlags
          inTimeStamp:(const AudioTimeStamp *)inTimeStamp
          inBusNumber:(UInt32)inBusNumber
        inNumberFrame:(UInt32)inNumberFrame
{
    // Retrieve input samples.
    OSStatus error = AudioUnitRender(_auHAL,
                                     ioActionFlags,
                                     inTimeStamp,
                                     inBusNumber,
                                     inNumberFrame,
                                     _inputBufferList);
    
    if (error == noErr) {
        AudioBuffer *input = &_inputBufferList->mBuffers[0];
        if (input->mDataByteSize <= kRingBufferByteSize - _ringBufferOffset) {
            memcpy(_ringBuffer + _ringBufferOffset, input->mData, input->mDataByteSize);
            _ringBufferOffset += input->mDataByteSize;
        } else {
            UInt32 bufferRest = kRingBufferByteSize - _ringBufferOffset;
            memcpy(_ringBuffer + _ringBufferOffset, input->mData, bufferRest);
            memcpy(_ringBuffer, input->mData + bufferRest, input->mDataByteSize - bufferRest);
            _ringBufferOffset = input->mDataByteSize - bufferRest;
        }
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
