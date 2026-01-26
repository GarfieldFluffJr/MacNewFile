//
//  AppDelegate.m
//  MacNewFile
//
//  Created by Louie Yin on 2026-01-25.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Create menu bar icon (background top right)
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    NSImage *icon = [NSImage imageNamed:@"add"];
    icon.template = YES; // Adapt to light/dark mode
    icon.size = NSMakeSize(18, 18);
    self.statusItem.button.image = icon;
    
    // Create dropdown menu on click
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"MacNewFile is running" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    
    self.statusItem.menu = menu;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
