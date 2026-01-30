//
//  AppDelegate.m
//  MacNewFile
//
//  Created by Louie Yin on 2026-01-25.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@property (strong) NSWindow *settingsWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Enable the Finder extension
    [self setExtensionEnabled:YES];

    // Create menu bar icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    NSImage *icon = [NSImage imageNamed:@"add"];
    if (icon) {
        icon.size = NSMakeSize(18, 18);
        icon.template = YES;
        self.statusItem.button.image = icon;
    } else {
        self.statusItem.button.title = @"NF";  // Fallback to text
    }

    // Create dropdown menu on click
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"MacNewFile is running" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Settings" action:@selector(openSettings:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

    self.statusItem.menu = menu;

    // Register application in Login Items as a background app
    if (@available(macOS 13.0, *)) {
        SMAppService *service = [SMAppService mainAppService];
        if (service.status != SMAppServiceStatusEnabled) {
            NSError *error = nil;
            [service registerAndReturnError:&error];
            if (error) {
                NSLog(@"Failed to add to login items: %@", error);
            }
        }
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Disable the Finder extension when app quits
    [self setExtensionEnabled:NO];
}

- (void)openSettings:(id)sender {
    // If window already exists, just bring it to front
    if (self.settingsWindow) {
        [self.settingsWindow makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
        return;
    }

    // Create the settings window
    NSRect frame = NSMakeRect(0, 0, 500, 220);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
    self.settingsWindow = [[NSWindow alloc] initWithContentRect:frame
                                                      styleMask:style
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];

    self.settingsWindow.title = @"MacNewFile Settings";
    self.settingsWindow.releasedWhenClosed = NO;

    // Feature names for checkboxes
    NSArray *features = @[
        @"Copy Path",
        @"Text File",
        @"Markdown File",
        @"Microsoft Word Document",
        @"Microsoft Excel Spreadsheet",
        @"Microsoft PowerPoint Presentation",
        @"Pages Document",
        @"Numbers Spreadsheet",
        @"Keynote Presentation",
        @"Enable notifications"
    ];

    // Create checkboxes in 2 columns
    NSView *contentView = self.settingsWindow.contentView;
    CGFloat checkboxHeight = 30;
    CGFloat columnWidth = (frame.size.width - 40) / 2;
    CGFloat leftX = 20;
    CGFloat rightX = 20 + columnWidth;
    CGFloat startY = frame.size.height - 50;

    for (NSUInteger i = 0; i < features.count; i++) {
        NSString *feature = features[i];
        NSButton *checkbox = [NSButton checkboxWithTitle:feature target:nil action:nil];

        NSUInteger column = i % 2;
        NSUInteger row = i / 2;
        CGFloat xPos = (column == 0) ? leftX : rightX;
        CGFloat yPos = startY - (row * checkboxHeight);

        checkbox.frame = NSMakeRect(xPos, yPos, columnWidth, checkboxHeight);
        checkbox.state = NSControlStateValueOn;
        [contentView addSubview:checkbox];
    }

    // Center the window on screen
    [self.settingsWindow center];

    // Show the window and bring app to front
    [self.settingsWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)setExtensionEnabled:(BOOL)enabled {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/pluginkit";
    task.arguments = @[
        @"-e",
        enabled ? @"use" : @"ignore",
        @"-i",
        @"com.louieyin.MacNewFile.MacNewFileFinderExtension"
    ];
    [task launch];
    [task waitUntilExit];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
