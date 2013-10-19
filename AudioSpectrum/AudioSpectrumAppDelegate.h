#import <Cocoa/Cocoa.h>

@interface AudioSpectrumAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *spectrumView;
@property (assign) IBOutlet NSPopUpButton *fftPointPopUp;
@property (assign) IBOutlet NSPopUpButton *bandTypePopUp;

- (IBAction)updateConfiguration:(id)sender;

@end
