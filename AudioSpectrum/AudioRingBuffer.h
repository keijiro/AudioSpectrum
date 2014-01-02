// AudioSpectrum: A sample app using Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>

@interface AudioRingBuffer : NSObject
{
@private
    Float32 *_samples;
    NSUInteger _offset;
}

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length;
- (void)addTo:(Float32 *)destination length:(NSUInteger)length;
- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length;
- (void)vectorAverageWith:(Float32 *)destination index:(NSUInteger)index length:(NSUInteger)length;
- (float)calculateRMS:(NSUInteger)length;
- (void)pushSamples:(Float32 *)source count:(NSUInteger)count;

@end
