// Application delegate.
// by Keijiro Takahashi, 2013
// https://github.com/keijiro/AudioSpectrum

#import "AudioSpectrumAppDelegate.h"
#import "AudioInputBuffer.h"
#import "SpectrumAnalyzer.h"

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[AudioInputBuffer sharedInstance] start];
    
    // Reset to the default settings.
    [self.fftPointPopUp selectItemAtIndex:1];
    [SpectrumAnalyzer sharedInstance].pointNumber = 1024;
    
    [self.bandTypePopUp selectItemAtIndex:2];
    [SpectrumAnalyzer sharedInstance].bandType = 2;
    
    // Set up the timer for refreshing.
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 30) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)redraw
{
    [self.spectrumView setNeedsDisplay:YES];
}

- (IBAction)updateConfiguration:(id)sender
{
    static const int pointNumbers[] = { 512, 1024, 2048, 4096 };
    [SpectrumAnalyzer sharedInstance].pointNumber = pointNumbers[self.fftPointPopUp.indexOfSelectedItem];
    [SpectrumAnalyzer sharedInstance].bandType = self.bandTypePopUp.indexOfSelectedItem;
}

@end
