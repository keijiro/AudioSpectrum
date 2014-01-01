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
    IBOutlet NSPopUpButton *_fftPointPopUp;
    IBOutlet NSPopUpButton *_bandTypePopUp;
}
@end

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [AudioInputHandler.sharedInstance start];
    
    // Reset to the default settings.
    [_fftPointPopUp selectItemAtIndex:1];
    SpectrumAnalyzer.sharedInstance.pointNumber = 1024;
    
    [_bandTypePopUp selectItemAtIndex:2];
    SpectrumAnalyzer.sharedInstance.bandType = 2;
    
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

- (IBAction)updateConfiguration:(id)sender
{
    static const int pointNumbers[] = { 512, 1024, 2048, 4096, 8192 };
    SpectrumAnalyzer.sharedInstance.pointNumber = pointNumbers[_fftPointPopUp.indexOfSelectedItem];
    SpectrumAnalyzer.sharedInstance.bandType = _bandTypePopUp.indexOfSelectedItem;
}

@end
