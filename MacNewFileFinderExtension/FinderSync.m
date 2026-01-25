//
//  FinderSync.m
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import "FinderSync.h"

@interface FinderSync ()

@property NSURL *myFolderURL;

@end

@implementation FinderSync

- (instancetype)init {
    self = [super init];

    NSLog(@"%s launched from %@ ; compiled at %s", __PRETTY_FUNCTION__, [[NSBundle mainBundle] bundlePath], __TIME__);
    
    // Monitor where users might right-click
    NSMutableSet *directories = [NSMutableSet set];
    
    // Add root volume
    [directories addObject:[NSURL fileURLWithPath:@"/"]];
    
    // Add user's home directory
    [directories addObject:[NSURL fileURLWithPath:NSHomeDirectory()]];
    
    // Add Desktop
    NSArray *desktopPaths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    if (desktopPaths.count > 0) {
        [directories addObject:[NSURL fileURLWithPath:desktopPaths[0]]];
    }
    
    [FIFinderSyncController defaultController].directoryURLs = directories;

//    // Set up the directory we are syncing.
//    self.myFolderURL = [NSURL fileURLWithPath:@"/Users/Shared/MySyncExtension Documents"];
//    [FIFinderSyncController defaultController].directoryURLs = [NSSet setWithObject:self.myFolderURL];
//
//    // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
//    [[FIFinderSyncController defaultController] setBadgeImage:[NSImage imageNamed: NSImageNameColorPanel] label:@"Status One" forBadgeIdentifier:@"One"];
//    [[FIFinderSyncController defaultController] setBadgeImage:[NSImage imageNamed: NSImageNameCaution] label:@"Status Two" forBadgeIdentifier:@"Two"];
    
    return self;
}

#pragma mark - Primary Finder Sync protocol methods

- (void)beginObservingDirectoryAtURL:(NSURL *)url {
    // The user is now seeing the container's contents.
    // If they see it in more than one view at a time, we're only told once.
    NSLog(@"beginObservingDirectoryAtURL:%@", url.filePathURL);
}


- (void)endObservingDirectoryAtURL:(NSURL *)url {
    // The user is no longer seeing the container's contents.
    NSLog(@"endObservingDirectoryAtURL:%@", url.filePathURL);
}

- (void)requestBadgeIdentifierForURL:(NSURL *)url {
    NSLog(@"requestBadgeIdentifierForURL:%@", url.filePathURL);
    
    // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
    NSInteger whichBadge = [url.filePathURL hash] % 3;
    NSString* badgeIdentifier = @[@"", @"One", @"Two"][whichBadge];
    [[FIFinderSyncController defaultController] setBadgeIdentifier:badgeIdentifier forURL:url];
}

#pragma mark - Menu and toolbar item support

- (NSString *)toolbarItemName {
    return @"MacNewFileFinderExtension";
}

- (NSString *)toolbarItemToolTip {
    return @"MacNewFileFinderExtension: Click the toolbar item for a menu.";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameCaution];
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)whichMenu {
    // Produce a menu for the extension.
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    // Add "New Text File" to menu
    NSMenuItem *newFileItem = [menu addItemWithTitle:@"New Text File" action:@selector(createNewTextFile:) keyEquivalent:@""];
    
    newFileItem.image = [NSImage imageNamed:NSImageNameAddTemplate];
    
//    [menu addItemWithTitle:@"Example Menu Item" action:@selector(sampleAction:) keyEquivalent:@""];

    return menu;
}

// Function to create new text file
- (void)createNewTextFile:(id)sender {
    // Get the folder where the user right clicked in
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    
    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }
    
    // Create filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"txt";
    // Create the full file pathname
    NSURL *fileURL = [targetURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];
    
    // If "Untitled" already exists, add a number to it
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    
    while ([fm fileExistsAtPath:fileURL.path]) {
        fileURL = [targetURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension]];
        counter++;
    }
    
    // Create the empty file
    NSError *error = nil;
    BOOL success = [@"" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (success) {
        NSLog(@"Created file: %@", fileURL.path);
        // Finder will automatically select new files so you can rename immediately
    } else {
        NSLog(@"Failed to create file: %@", error.localizedDescription);
    }
}

- (IBAction)sampleAction:(id)sender {
    NSURL* target = [[FIFinderSyncController defaultController] targetedURL];
    NSArray* items = [[FIFinderSyncController defaultController] selectedItemURLs];

    NSLog(@"sampleAction: menu item: %@, target = %@, items = ", [sender title], [target filePathURL]);
    [items enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSLog(@"    %@", [obj filePathURL]);
    }];
}

@end

