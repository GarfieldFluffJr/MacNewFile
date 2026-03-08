//
//  FinderSync.m
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import "FinderSync.h"

@implementation FinderSync

- (instancetype)init {
    self = [super init];
    if (self) {
        [FIFinderSyncController defaultController].directoryURLs = [NSSet setWithObject:[NSURL fileURLWithPath:@"/"]];
    }
    return self;
}

#pragma mark - Menu and toolbar item support

- (NSString *)toolbarItemName {
    // Better fallback value requested by Greptile
    return NSLocalizedString(@"New File", nil);
}

- (NSString *)toolbarItemToolTip {
    return NSLocalizedString(@"MacNewFileFinderExtension: Click the toolbar item for a menu.", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAddTemplate];
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)whichMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    // Copy Path
    NSMenuItem *copyPathItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Path", nil) action:@selector(copyPathToClipboard:) keyEquivalent:@""];
    NSImage *copyIcon = [NSImage imageNamed:@"copy"];
    copyIcon.template = YES;
    copyPathItem.image = copyIcon;
    [menu addItem:copyPathItem];

    // Open Terminal
    NSMenuItem *openTerminalItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open New Terminal", nil) action:@selector(openTerminalAtPath:) keyEquivalent:@""];
    NSImage *terminalIcon = [NSImage imageNamed:@"terminal"];
    terminalIcon.template = YES;
    openTerminalItem.image = terminalIcon;
    [menu addItem:openTerminalItem];

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@""];

    // Text File
    NSMenuItem *newTextItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Text File", nil) action:@selector(createNewTextFile:) keyEquivalent:@""];
    NSImage *textIcon = [NSImage imageNamed:@"edit"];
    textIcon.template = YES;
    newTextItem.image = textIcon;
    [submenu addItem:newTextItem];

    // Markdown
    NSMenuItem *newMarkdownItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Markdown File", nil) action:@selector(createNewMarkdownFile:) keyEquivalent:@""];
    NSImage *markdownIcon = [NSImage imageNamed:@"document"];
    markdownIcon.template = YES;
    newMarkdownItem.image = markdownIcon;
    [submenu addItem:newMarkdownItem];

    // Word
    NSMenuItem *newWordItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Microsoft Word Document", nil) action:@selector(createNewWordDocument:) keyEquivalent:@""];
    NSImage *wordIcon = [NSImage imageNamed:@"word"];
    wordIcon.template = YES;
    newWordItem.image = wordIcon;
    [submenu addItem:newWordItem];

    // Excel
    NSMenuItem *newExcelItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Microsoft Excel Spreadsheet", nil) action:@selector(createNewExcelDocument:) keyEquivalent:@""];
    NSImage *excelIcon = [NSImage imageNamed:@"excel"];
    excelIcon.template = YES;
    newExcelItem.image = excelIcon;
    [submenu addItem:newExcelItem];

    // PowerPoint
    NSMenuItem *newPowerPointItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Microsoft PowerPoint Presentation", nil) action:@selector(createNewPowerPointDocument:) keyEquivalent:@""];
    NSImage *powerPointIcon = [NSImage imageNamed:@"powerpoint"];
    powerPointIcon.template = YES;
    newPowerPointItem.image = powerPointIcon;
    [submenu addItem:newPowerPointItem];

    // Pages
    NSMenuItem *newPagesItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Pages Document", nil) action:@selector(createNewPagesDocument:) keyEquivalent:@""];
    NSImage *pagesIcon = [NSImage imageNamed:@"pages"];
    pagesIcon.template = YES;
    newPagesItem.image = pagesIcon;
    [submenu addItem:newPagesItem];

    // Numbers
    NSMenuItem *newNumbersItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Numbers Spreadsheet", nil) action:@selector(createNewNumbersDocument:) keyEquivalent:@""];
    NSImage *numbersIcon = [NSImage imageNamed:@"numbers"];
    numbersIcon.template = YES;
    newNumbersItem.image = numbersIcon;
    [submenu addItem:newNumbersItem];

    // Keynote
    NSMenuItem *newKeynoteItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Keynote Presentation", nil) action:@selector(createNewKeynoteDocument:) keyEquivalent:@""];
    NSImage *keynoteIcon = [NSImage imageNamed:@"keynote"];
    keynoteIcon.template = YES;
    newKeynoteItem.image = keynoteIcon;
    [submenu addItem:newKeynoteItem];

    // Main Item
    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File", nil) action:nil keyEquivalent:@""];
    NSImage *mainIcon = [NSImage imageNamed:@"add"];
    mainItem.image = mainIcon;
    mainItem.submenu = submenu;
    [menu addItem:mainItem];

    return menu;
}

// --- Helper method to reveal file safely ---

- (void)revealFilePath:(NSString *)filePath {
    if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:filePath]]];
    }
}

// --- Core Creation Methods (Native macOS APIs) ---

// Used for empty files like .txt or .md
- (void)createEmptyFileWithExtension:(NSString *)extension {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Ensure unique filename
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", baseName, counter++, extension]];
    }
    
    // Native creation
    BOOL success = [fm createFileAtPath:filePath contents:nil attributes:nil];
    if (success) {
        [self revealFilePath:filePath];
    } else {
        NSLog(@"Failed to create empty file at path: %@", filePath);
    }
}

// Used for complex files that require copying a template bundle (Pages, Word, etc.)
- (void)createFileFromTemplateWithExtension:(NSString *)extension {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", baseName, counter++, extension]];
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *templatePath = [bundle pathForResource:@"Blank" ofType:extension];
    
    if (!templatePath) {
        NSLog(@"Template Blank.%@ not found in bundle.", extension);
        return;
    }
    
    // Native copy
    NSError *error = nil;
    BOOL success = [fm copyItemAtPath:templatePath toPath:filePath error:&error];
    
    if (success) {
        [self revealFilePath:filePath];
    } else {
        NSLog(@"Failed to copy template to path: %@. Error: %@", filePath, error.localizedDescription);
    }
}


// --- Action Handlers ---

- (void)createNewTextFile:(id)sender { [self createEmptyFileWithExtension:@"txt"]; }
- (void)createNewMarkdownFile:(id)sender { [self createEmptyFileWithExtension:@"md"]; }

// Office - Requires Blank.docx, Blank.xlsx, Blank.pptx to be added to the Xcode project bundle
- (void)createNewWordDocument:(id)sender { [self createFileFromTemplateWithExtension:@"docx"]; }
- (void)createNewExcelDocument:(id)sender { [self createFileFromTemplateWithExtension:@"xlsx"]; }
- (void)createNewPowerPointDocument:(id)sender { [self createFileFromTemplateWithExtension:@"pptx"]; }

// iWork
- (void)createNewPagesDocument:(id)sender { [self createFileFromTemplateWithExtension:@"pages"]; }
- (void)createNewNumbersDocument:(id)sender { [self createFileFromTemplateWithExtension:@"numbers"]; }
- (void)createNewKeynoteDocument:(id)sender { [self createFileFromTemplateWithExtension:@"key"]; }

// --- Utilities ---

- (void)copyPathToClipboard:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (targetURL) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:targetURL.path forType:NSPasteboardTypeString];
    }
}

- (void)openTerminalAtPath:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    
    NSURL *terminalURL = [NSURL fileURLWithPath:@"/System/Applications/Utilities/Terminal.app"];
    
    NSWorkspaceOpenConfiguration *config = [[NSWorkspaceOpenConfiguration alloc] init];
    
    [[NSWorkspace sharedWorkspace] openURLs:@[targetURL]
                       withApplicationAtURL:terminalURL
                              configuration:config
                          completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            // Use localized error message
            NSString *errorMessage = NSLocalizedString(@"Failed to open Terminal", nil);
            NSLog(@"%@: %@", errorMessage, error.localizedDescription);
        }
    }];
}

@end
