// AudioSpectrum: A sample app using Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import "AudioSpectrumAppDelegate.h"
#import "AudioInputHandler.h"

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [AudioInputHandler.sharedInstance start];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
