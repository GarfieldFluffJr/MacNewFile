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

    // Add root volume - covers most locations
    [directories addObject:[NSURL fileURLWithPath:@"/"]];

    // Add all mounted volumes
    [directories addObject:[NSURL fileURLWithPath:@"/Volumes"]];

    // Add user's home directory
    [directories addObject:[NSURL fileURLWithPath:NSHomeDirectory()]];

    // Add Desktop (local)
    NSArray *desktopPaths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    if (desktopPaths.count > 0) {
        NSString *desktopPath = desktopPaths[0];
        [directories addObject:[NSURL fileURLWithPath:desktopPath]];
        NSLog(@"Monitoring local Desktop: %@", desktopPath);
    }

    // Add iCloud Desktop & Documents (if iCloud is enabled, Desktop might be here)
    NSString *iCloudDesktop = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Mobile Documents/com~apple~CloudDocs/Desktop"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:iCloudDesktop]) {
        [directories addObject:[NSURL fileURLWithPath:iCloudDesktop]];
        NSLog(@"Monitoring iCloud Desktop: %@", iCloudDesktop);
    }

    // Also add the iCloud root
    NSString *iCloudRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Mobile Documents/com~apple~CloudDocs"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:iCloudRoot]) {
        [directories addObject:[NSURL fileURLWithPath:iCloudRoot]];
    }

    // Add Documents folder
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (docPaths.count > 0) {
        [directories addObject:[NSURL fileURLWithPath:docPaths[0]]];
    }

    // Add Downloads folder
    NSArray *downloadPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    if (downloadPaths.count > 0) {
        [directories addObject:[NSURL fileURLWithPath:downloadPaths[0]]];
    }

    NSLog(@"MacNewFile: Monitoring %lu directories", (unsigned long)directories.count);
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
    // Log menu requests for debugging
    NSURL *target = [[FIFinderSyncController defaultController] targetedURL];
    NSLog(@"MacNewFile: menuForMenuKind:%ld targetURL:%@", (long)whichMenu, target);

    // Create the main menu
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    // Create the main "New File" menu item with submenu
    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:@"New File" action:nil keyEquivalent:@""];
    NSImage *mainIcon = [NSImage imageNamed:@"add"];
    mainIcon.template = YES;
    mainItem.image = mainIcon;

    // Create submenu
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@""];

    // Add "New Text File" to submenu
    NSMenuItem *newTextItem = [[NSMenuItem alloc] initWithTitle:@"Text File" action:@selector(createNewTextFile:) keyEquivalent:@""];
    NSImage *textIcon = [NSImage imageNamed:@"edit"];
    textIcon.template = YES;
    newTextItem.image = textIcon;
    [submenu addItem:newTextItem];

    // Add "New Microsoft Word Document" to submenu
    NSMenuItem *newWordItem = [[NSMenuItem alloc] initWithTitle:@"Microsoft Word Document" action:@selector(createNewWordDocument:) keyEquivalent:@""];
    NSImage *wordIcon = [NSImage imageNamed:@"word"];
    wordIcon.template = YES;
    newWordItem.image = wordIcon;
    [submenu addItem:newWordItem];

    // Add "New Pages Document" to submenu
    NSMenuItem *newPagesItem = [[NSMenuItem alloc] initWithTitle:@"Pages Document" action:@selector(createNewPagesDocument:) keyEquivalent:@""];
    NSImage *pagesIcon = [NSImage imageNamed:@"pages"];
    pagesIcon.template = YES;
    newPagesItem.image = pagesIcon;
    [submenu addItem:newPagesItem];

    // Attach submenu to main item
    mainItem.submenu = submenu;
    [menu addItem:mainItem];

    return menu;
}

// Function to create new Word document
- (void)createNewWordDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"docx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    // Create blank .docx using shell script
    // .docx is a zip file containing XML files
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/word\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/word/document.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"word/document.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:document xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:body><w:p><w:r><w:t></w:t></w:r></w:p></w:body></w:document>' > \\\"$TMPDIR/word/document.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to create Word document: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

// Function to create new Pages document
- (void)createNewPagesDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"pages";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    // Get the blank template from the bundle
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *templatePath = [bundle pathForResource:@"Blank" ofType:@"pages"];

    if (!templatePath) {
        NSLog(@"Failed to find Blank.pages template in bundle");
        return;
    }

    // Copy template to destination using AppleScript (to bypass sandbox)
    NSString *escapedTemplate = [templatePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *escapedDest = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \"cp -R '%@' '%@'\"", escapedTemplate, escapedDest];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to create Pages document: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
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
    // Create the full file pathname as a NSString instead of NSURL
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];
    
    // If "Untitled" already exists, add a number to it
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }
    
    // Use AppleScript to create a new file and bypass sandboxing permissions
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'"
                                                                withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"touch '%@'\"", escapedPath];
    
    // Run AppleScript
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];
    
    if (errorDict) {
        NSLog(@"Failed: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        
        // Select the file in Finder using NSWorkspace (which doesn't need Apple Events)
        // Sandbox heavily restricts apple events
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
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

