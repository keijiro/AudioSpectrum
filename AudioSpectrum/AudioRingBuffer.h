// Ring buffer for handling audio samples.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import <Foundation/Foundation.h>

@interface AudioRingBuffer : NSObject

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length;
- (void)addTo:(Float32 *)destination length:(NSUInteger)length;
- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length;
- (void)vectorAverageWith:(Float32 *)destination index:(NSUInteger)index length:(NSUInteger)length;
- (float)calculateRMS:(NSUInteger)length;
- (void)pushSamples:(Float32 *)source count:(NSUInteger)count;

@end
