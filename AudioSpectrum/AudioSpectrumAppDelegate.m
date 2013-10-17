#import "AudioSpectrumAppDelegate.h"
#import "AudioInputBuffer.h"

@implementation AudioSpectrumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[AudioInputBuffer sharedInstance] start];
}

@end
