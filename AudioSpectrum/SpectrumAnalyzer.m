// AudioSpectrum: A sample app using Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import "SpectrumAnalyzer.h"
#import "AudioInputHandler.h"
#import "AudioRingBuffer.h"

// Octave band type definition
static Float32 middleFrequenciesForBands[][32] = {
    { 125.0f, 500, 1000, 2000 },
    { 250.0f, 400, 600, 800 },
    { 63.0f, 125, 500, 1000, 2000, 4000, 6000, 8000 },
    { 31.5f, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 },
    { 25.0f, 31.5f, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000 },
    { 20.0f, 25, 31.5f, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000 }
};

static Float32 bandwidthForBands[] = {
    1.41421356237f, // 2^(1/2)
    1.25992104989f, // 2^(1/3)
    1.41421356237f, // 2^(1/2)
    1.41421356237f, // 2^(1/2)
    1.12246204831f, // 2^(1/6)
    1.12246204831f  // 2^(1/6)
};

NSUInteger CountBands(NSUInteger bandType)
{
    for (NSUInteger i = 0;; i++)
        if (middleFrequenciesForBands[bandType][i] == 0) return i;
}

#pragma mark

@implementation SpectrumAnalyzer

#pragma mark Constructor / Destructor

- (id)init
{
    if (self = [super init])
    {
        self.pointNumber = 1024;
        self.octaveBandType = OctaveBandTypeStandard;
    }
    return self;
}

- (void)dealloc
{
    vDSP_DFT_DestroySetup(_dftSetup);
    
    free(_dftBuffer.realp);
    free(_dftBuffer.imagp);
    free(_inputBuffer);
    free(_window);
    free(_rawSpectrum);
    free(_octaveBandSpectrum);
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark Custom Property Accessors

- (NSUInteger)pointNumber
{
    return _pointNumber;
}

- (void)setPointNumber:(NSUInteger)number
{
    if (_pointNumber == number) return;
    
    // Free the related objects if already initialized.
    if (_pointNumber != 0)
    {
        free(_dftBuffer.realp);
        free(_dftBuffer.imagp);
        free(_inputBuffer);
        free(_window);
        free(_rawSpectrum);
    }
    
    // Update the number.
    _pointNumber = number;
    
    if (number > 0)
    {
        // Reallocate the related objects.
        _dftSetup = vDSP_DFT_zrop_CreateSetup(_dftSetup, _pointNumber, vDSP_DFT_FORWARD);
        
        _dftBuffer.realp = calloc(_pointNumber / 2, sizeof(Float32));
        _dftBuffer.imagp = calloc(_pointNumber / 2, sizeof(Float32));
        
        _inputBuffer = calloc(_pointNumber, sizeof(Float32));
        
        _window = calloc(_pointNumber, sizeof(Float32));
        vDSP_blkman_window(_window, number, 0);
        
        Float32 normFactor = 2.0f / number;
        vDSP_vsmul(_window, 1, &normFactor, _window, 1, number);
        
        _rawSpectrum = calloc(sizeof(SpectrumData) + sizeof(Float32) * _pointNumber / 2, 1);
        _rawSpectrum->length = _pointNumber / 2;
    }
}

- (NSUInteger)octaveBandType
{
    return _octaveBandType;
}

- (void)setOctaveBandType:(NSUInteger)number
{
    if (_octaveBandType == number) return;
    
    // Update the number.
    _octaveBandType = number;
    
    // Reallocate the buffer;
    if (_octaveBandSpectrum) free(_octaveBandSpectrum);
    NSUInteger bandCount = CountBands(_octaveBandType);
    _octaveBandSpectrum = calloc(sizeof(SpectrumData) + sizeof(Float32) * bandCount, 1);
    _octaveBandSpectrum->length = bandCount;
}

- (SpectrumDataRef)rawSpectrumData
{
    return _rawSpectrum;
}

- (SpectrumDataRef)octaveBandSpectrumData
{
    return _octaveBandSpectrum;
}

#pragma mark Audio Processing Methods

- (void)processAudioInput:(AudioInputHandler *)input allChannels:(BOOL)allChannels
{
    if (allChannels)
    {
        // Retrieve waveforms from channels and average these.
        [input.ringBuffers.firstObject copyTo:_inputBuffer length:_pointNumber];
        for (NSUInteger i = 1; i < input.ringBuffers.count; i++)
            [[input.ringBuffers objectAtIndex:i] vectorAverageWith:_inputBuffer index:i length:_pointNumber];
        
        // Fourier transform.
        [self calculateWithInputBuffer:input.sampleRate];
    }
    else
    {
        [self processAudioInput:input channel:0];
    }
}

- (void)processAudioInput:(AudioInputHandler *)input channel:(NSUInteger)channel
{
    // Retrieve a waveform from the specified channel.
    [[input.ringBuffers objectAtIndex:channel] copyTo:_inputBuffer length:_pointNumber];
    
    // Fourier transform.
    [self calculateWithInputBuffer:input.sampleRate];
}

- (void)processAudioInput:(AudioInputHandler *)input channel1:(NSUInteger)channel1 channel2:(NSUInteger)channel2
{
    // Retrieve waveforms from the specified channel.
    [[input.ringBuffers objectAtIndex:channel1] copyTo:_inputBuffer length:_pointNumber];
    [[input.ringBuffers objectAtIndex:channel2] vectorAverageWith:_inputBuffer index:1 length:_pointNumber];
    
    // Fourier transform.
    [self calculateWithInputBuffer:input.sampleRate];
}

- (void)calculateWithInputBuffer:(float)sampleRate
{
    NSUInteger length = _pointNumber / 2;
    
    // Split the waveform.
    DSPSplitComplex dest = { _dftBuffer.realp, _dftBuffer.imagp };
    vDSP_ctoz((const DSPComplex*)_inputBuffer, 2, &dest, 1, length);
    
    // Apply the window function.
    vDSP_vmul(_dftBuffer.realp, 1, _window, 2, _dftBuffer.realp, 1, length);
    vDSP_vmul(_dftBuffer.imagp, 1, _window + 1, 2, _dftBuffer.imagp, 1, length);

    // FFT.
    vDSP_DFT_Execute(_dftSetup, _dftBuffer.realp, _dftBuffer.imagp, _dftBuffer.realp, _dftBuffer.imagp);
    
    // Zero out the nyquist value.
    _dftBuffer.imagp[0] = 0;
    
    // Calculate power spectrum.
    Float32 *rawSpectrum = _rawSpectrum->data;
    vDSP_zvmags(&_dftBuffer, 1, rawSpectrum, 1, length);
    
    // Add -128db offset to avoid log(0).
    float kZeroOffset = 1.5849e-13;
    vDSP_vsadd(rawSpectrum, 1, &kZeroOffset, rawSpectrum, 1, length);

    // Convert power to decibel.
    float kZeroDB = 0.70710678118f; // 1/sqrt(2)
    vDSP_vdbcon(rawSpectrum, 1, &kZeroDB, rawSpectrum, 1, length, 0);

    // Calculate the band levels.
    NSUInteger bandCount = _octaveBandSpectrum->length;
    
    const Float32 *middleFreqs = middleFrequenciesForBands[_octaveBandType];
    Float32 bandWidth = bandwidthForBands[_octaveBandType];
    
    Float32 freqToIndexCoeff = _pointNumber / sampleRate;
    int maxIndex = (int)_pointNumber / 2 - 1;
    
    for (NSUInteger band = 0; band < bandCount; band++)
    {
        int idxlo = MIN((int)floorf(middleFreqs[band] / bandWidth * freqToIndexCoeff), maxIndex);
        int idxhi = MIN((int)floorf(middleFreqs[band] * bandWidth * freqToIndexCoeff), maxIndex);
        
        Float32 maxLevel = rawSpectrum[idxlo];
        for (int i = idxlo + 1; i <= idxhi; i++)
            maxLevel = MAX(maxLevel, rawSpectrum[i]);
        
        _octaveBandSpectrum->data[band] = maxLevel;
    }
}

@end
