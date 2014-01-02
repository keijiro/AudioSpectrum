// AudioSpectrum: An example for Audio Unit and vDSP
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/AudioSpectrum

#import "AudioSpectrumAppDelegate.h"
#import "AudioInputHandler.h"
#import "SpectrumAnalyzer.h"

@interface AudioSpectrumAppDelegate ()
{
    IBOutlet NSWindow *_window;
    IBOutlet NSView *_spectrumView;
}
@end

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [AudioInputHandler.sharedInstance start];
    
    // Set up the timer for refreshing.
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 60) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)redraw
{
    _spectrumView.needsDisplay = YES;
}

@end
