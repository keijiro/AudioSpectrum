// AudioSpectrum: A sample app using Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import "AudioSpectrumAppDelegate.h"
#import "AudioInputHandler.h"

#import <AVFoundation/AVFoundation.h>

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (@available(macOS 10.14, *)) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) {
                [AudioInputHandler.sharedInstance start];
            } else {
                NSAssert(true, @"Failed to get microphone permission.");
            }
        }];
    } else {
        [AudioInputHandler.sharedInstance start];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
