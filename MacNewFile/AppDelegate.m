//
//  AppDelegate.m
//  MacNewFile
//
//  Created by Louie Yin on 2026-01-25.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>

static NSString * const kAppGroupIdentifier = @"group.com.louieyin.MacNewFile";

// Feature keys for UserDefaults
static NSString * const kFeatureCopyPath = @"feature_copy_path";
static NSString * const kFeatureTextFile = @"feature_text_file";
static NSString * const kFeatureMarkdownFile = @"feature_markdown_file";
static NSString * const kFeatureWordDocument = @"feature_word_document";
static NSString * const kFeatureExcelSpreadsheet = @"feature_excel_spreadsheet";
static NSString * const kFeaturePowerPointPresentation = @"feature_powerpoint_presentation";
static NSString * const kFeaturePagesDocument = @"feature_pages_document";
static NSString * const kFeatureNumbersSpreadsheet = @"feature_numbers_spreadsheet";
static NSString * const kFeatureKeynotePresentation = @"feature_keynote_presentation";

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@property (strong) NSWindow *settingsWindow;
@property (strong) NSUserDefaults *sharedDefaults;

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
    NSRect frame = NSMakeRect(0, 0, 500, 300);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
    self.settingsWindow = [[NSWindow alloc] initWithContentRect:frame
                                                      styleMask:style
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];

    self.settingsWindow.title = @"MacNewFile Settings";
    self.settingsWindow.releasedWhenClosed = NO;
    self.settingsWindow.backgroundColor = [NSColor colorWithRed:249/255.0 green:250/255.0 blue:251/255.0 alpha:1.0];

    NSView *contentView = self.settingsWindow.contentView;

    // Add header at the top
    NSTextField *header = [NSTextField labelWithString:@"Customize your Finder right-click menu."];
    header.frame = NSMakeRect(20, frame.size.height - 35, frame.size.width - 40, 20);
    header.font = [NSFont boldSystemFontOfSize:15];
    [contentView addSubview:header];

    // Add subtitle below header
    NSTextField *subtitle = [NSTextField labelWithString:@"Toggle any features you wish to add/remove."];
    subtitle.frame = NSMakeRect(20, frame.size.height - 55, frame.size.width - 40, 20);
    subtitle.font = [NSFont systemFontOfSize:13];
    subtitle.textColor = [NSColor secondaryLabelColor];
    [contentView addSubview:subtitle];

    // Add divider line
    NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(20, frame.size.height - 65, frame.size.width - 40, 1)];
    divider.boxType = NSBoxSeparator;
    [contentView addSubview:divider];

    // Initialize shared defaults
    self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];

    // Feature names and their corresponding keys
    NSArray *features = @[
        @{@"name": @"Copy Path", @"key": kFeatureCopyPath},
        @{@"name": @"Text File", @"key": kFeatureTextFile},
        @{@"name": @"Markdown File", @"key": kFeatureMarkdownFile},
        @{@"name": @"Microsoft Word Document", @"key": kFeatureWordDocument},
        @{@"name": @"Microsoft Excel Spreadsheet", @"key": kFeatureExcelSpreadsheet},
        @{@"name": @"Microsoft PowerPoint Presentation", @"key": kFeaturePowerPointPresentation},
        @{@"name": @"Pages Document", @"key": kFeaturePagesDocument},
        @{@"name": @"Numbers Spreadsheet", @"key": kFeatureNumbersSpreadsheet},
        @{@"name": @"Keynote Presentation", @"key": kFeatureKeynotePresentation},
    ];

    // Create checkboxes in 2 columns
    CGFloat checkboxHeight = 30;
    CGFloat columnWidth = (frame.size.width - 40) / 2;
    CGFloat leftX = 20;
    CGFloat rightX = 20 + columnWidth;
    CGFloat startY = frame.size.height - 105;

    for (NSUInteger i = 0; i < features.count; i++) {
        NSDictionary *feature = features[i];
        NSString *name = feature[@"name"];
        NSString *key = feature[@"key"];

        NSButton *checkbox = [NSButton checkboxWithTitle:name target:self action:@selector(checkboxToggled:)];
        checkbox.identifier = key;

        NSUInteger column = i % 2;
        NSUInteger row = i / 2;
        CGFloat xPos = (column == 0) ? leftX : rightX;
        CGFloat yPos = startY - (row * checkboxHeight);

        checkbox.frame = NSMakeRect(xPos, yPos, columnWidth, checkboxHeight);

        // Load saved state (default to ON if not set)
        id savedValue = [self.sharedDefaults objectForKey:key];
        if (savedValue == nil) {
            checkbox.state = NSControlStateValueOn;
            [self.sharedDefaults setBool:YES forKey:key];
        } else {
            checkbox.state = [self.sharedDefaults boolForKey:key] ? NSControlStateValueOn : NSControlStateValueOff;
        }

        [contentView addSubview:checkbox];
    }

    [self.sharedDefaults synchronize];

    // Center the window on screen
    [self.settingsWindow center];

    // Show the window and bring app to front
    [self.settingsWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)checkboxToggled:(NSButton *)sender {
    NSString *key = sender.identifier;
    BOOL isEnabled = (sender.state == NSControlStateValueOn);
    [self.sharedDefaults setBool:isEnabled forKey:key];
    [self.sharedDefaults synchronize];
    NSLog(@"Feature %@ set to %@", key, isEnabled ? @"ON" : @"OFF");
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
