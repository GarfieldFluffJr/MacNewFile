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
