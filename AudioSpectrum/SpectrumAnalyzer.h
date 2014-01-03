// AudioSpectrum: A sample app using Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@class AudioInputHandler;

// Octave band type definition.
typedef NS_ENUM(NSUInteger, OctaveBandType)
{
    OctaveBandType4,
    OctaveBandTypeVisual,
    OctaveBandType8,
    OctaveBandTypeStandard,
    OctaveBandType24,
    OctaveBandType31
};

// Data structure for spectrum data.
struct SpectrumData
{
    NSUInteger length;
    Float32 data[0];
};
typedef struct SpectrumData SpectrumData;
typedef const struct SpectrumData *SpectrumDataRef;

// Spectrum analyzer class interface.
@interface SpectrumAnalyzer : NSObject
{
@private
    // Configurations.
    NSUInteger _pointNumber;
    NSUInteger _octaveBandType;
    
    // DFT objects.
    vDSP_DFT_Setup _dftSetup;
    DSPSplitComplex _dftBuffer;
    Float32 *_inputBuffer;
    Float32 *_window;
    
    // Spectrum data.
    SpectrumData *_rawSpectrum;
    SpectrumData *_octaveBandSpectrum;
}

// Configurations.
@property (nonatomic, assign) NSUInteger pointNumber;
@property (nonatomic, assign) NSUInteger octaveBandType;

// Spectrum data accessors.
@property (nonatomic, readonly) SpectrumDataRef rawSpectrumData;
@property (nonatomic, readonly) SpectrumDataRef octaveBandSpectrumData;

// Process the audio input.
- (void)processAudioInput:(AudioInputHandler *)handler allChannels:(BOOL)allChannels;
- (void)processAudioInput:(AudioInputHandler *)handler channel:(NSUInteger)channel;
- (void)processAudioInput:(AudioInputHandler *)handler channel1:(NSUInteger)channel1 channel2:(NSUInteger)channel2;

// Process the raw waveform data (the length of the waveform must equal to pointNumber).
- (void)processWaveform:(const Float32 *)waveform samleRate:(Float32)sampleRate;
- (void)processWaveform:(const Float32 *)waveform1 withAdding:(const Float32 *)waveform2 samleRate:(Float32)sampleRate;

@end
