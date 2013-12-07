#import <Foundation/Foundation.h>

@interface AudioRingBuffer : NSObject

- (void)copyTo:(Float32 *)destination length:(NSUInteger)length;
- (void)addTo:(Float32 *)destination length:(NSUInteger)length;
- (void)averageTo:(Float32 *)destination index:(NSUInteger)index length:(NSUInteger)length;
- (void)splitEvenTo:(Float32 *)even oddTo:(Float32 *)odd totalLength:(NSUInteger)length;
- (void)pushSamples:(Float32 *)source count:(NSUInteger)count;

@end
