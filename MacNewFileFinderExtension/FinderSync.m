//
//  FinderSync.m
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import "FinderSync.h"

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
static NSString * const kFeatureOpenTerminal = @"feature_open_terminal";

@interface FinderSync ()
@property (strong) NSUserDefaults *sharedDefaults;
@end

@implementation FinderSync

/// Finder draws menu icons in its own process; multi-appearance `NSImage`s from the asset catalog
/// can resolve incorrectly. Draw the catalog image under the target system appearance and keep a
/// single bitmap representation so light/dark assets always match Settings ▸ Appearance.
+ (NSImage *)singleLayerMenuImageFromCatalogImage:(NSImage *)image {
    if (!image) {
        return nil;
    }
    NSSize size = image.size;
    if (size.width <= 0 || size.height <= 0) {
        return image;
    }

    CGFloat scale = 2.0;
    NSScreen *screen = [NSScreen mainScreen];
    if (screen) {
        scale = screen.backingScaleFactor;
    }

    NSInteger pixelW = (NSInteger)ceil(size.width * scale);
    NSInteger pixelH = (NSInteger)ceil(size.height * scale);
    if (pixelW < 1) {
        pixelW = 1;
    }
    if (pixelH < 1) {
        pixelH = 1;
    }

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:pixelW
                                                                    pixelsHigh:pixelH
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bytesPerRow:pixelW * 4
                                                                  bitsPerPixel:32];
    rep.size = size;

    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    ctx.imageInterpolation = NSImageInterpolationHigh;
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:ctx];
    CGContextRef cg = ctx.CGContext;
    if (cg) {
        CGContextClearRect(cg, CGRectMake(0, 0, pixelW, pixelH));
    }
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
             fromRect:NSZeroRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0
       respectFlipped:NO
                hints:nil];
    [NSGraphicsContext restoreGraphicsState];

    NSImage *flat = [[NSImage alloc] initWithSize:size];
    [flat addRepresentation:rep];
    return flat;
}

/// Finder Sync runs in an XPC process; `NSAppearance` here often does not match the Finder window.
/// Menu images are handed to Finder and may be flattened, so asset-catalog dark/light must be
/// resolved explicitly using the user's system appearance.
- (BOOL)systemAppearanceIsDark {
    id style = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain] objectForKey:@"AppleInterfaceStyle"];
    if ([style isKindOfClass:[NSString class]] && [(NSString *)style length] > 0) {
        return [(NSString *)style caseInsensitiveCompare:@"Dark"] == NSOrderedSame;
    }
    if (@available(macOS 10.14, *)) {
        NSAppearance *app = NSApp.effectiveAppearance;
        if (app) {
            NSAppearanceName match = [app bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
            return [match isEqualToString:NSAppearanceNameDarkAqua];
        }
    }
    return NO;
}

- (NSImage *)contextMenuImageNamed:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleForClass:[FinderSync class]];
    NSImage *catalog = [bundle imageForResource:name];
    if (!catalog) {
        catalog = [NSImage imageNamed:name];
    }
    if (!catalog) {
        return nil;
    }

    BOOL dark = [self systemAppearanceIsDark];
    if (@available(macOS 10.14, *)) {
        NSAppearanceName appearanceName = dark ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua;
        NSAppearance *appearance = [NSAppearance appearanceNamed:appearanceName];
        if (appearance) {
            __block NSImage *flat = nil;
            [appearance performAsCurrentDrawingAppearance:^{
                flat = [FinderSync singleLayerMenuImageFromCatalogImage:catalog];
            }];
            return flat ?: catalog;
        }
    }
    return catalog;
}

- (instancetype)init {
    self = [super init];

    // Initialize shared defaults
    self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];

    // Monitor root filesystem - covers all local directories
    // Note: iCloud Drive is not supported due to macOS Sonoma+ limitations
    [FIFinderSyncController defaultController].directoryURLs = [NSSet setWithObject:[NSURL fileURLWithPath:@"/"]];

    return self;
}

- (BOOL)isFeatureEnabled:(NSString *)key {
    // Default to YES if not set
    id value = [self.sharedDefaults objectForKey:key];
    if (value == nil) {
        return YES;
    }
    return [self.sharedDefaults boolForKey:key];
}

#pragma mark - Primary Finder Sync protocol methods

- (void)beginObservingDirectoryAtURL:(NSURL *)url {
    // Called when user opens a directory in Finder
}


- (void)endObservingDirectoryAtURL:(NSURL *)url {
    // Called when user closes a directory in Finder
}

- (void)requestBadgeIdentifierForURL:(NSURL *)url {
    // Not used - no badge icons needed
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
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    // Add "Copy Path" menu item (if enabled)
    if ([self isFeatureEnabled:kFeatureCopyPath]) {
        NSMenuItem *copyPathItem = [[NSMenuItem alloc] initWithTitle:@"Copy Path" action:@selector(copyPathToClipboard:) keyEquivalent:@""];
        copyPathItem.image = [self contextMenuImageNamed:@"copy"];
        [menu addItem:copyPathItem];
    }

    // Add "Open Terminal" menu item (if enabled)
    if ([self isFeatureEnabled:kFeatureOpenTerminal]) {
        NSMenuItem *openTerminalItem = [[NSMenuItem alloc] initWithTitle:@"Open New Terminal" action:@selector(openTerminalAtPath:) keyEquivalent:@""];
        openTerminalItem.image = [self contextMenuImageNamed:@"terminal"];
        [menu addItem:openTerminalItem];
    }

    // Create submenu for New File options
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@""];

    // Add "New Text File" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureTextFile]) {
        NSMenuItem *newTextItem = [[NSMenuItem alloc] initWithTitle:@"Text File" action:@selector(createNewTextFile:) keyEquivalent:@""];
        newTextItem.image = [self contextMenuImageNamed:@"edit"];
        [submenu addItem:newTextItem];
    }

    // Add "New Markdown File" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureMarkdownFile]) {
        NSMenuItem *newMarkdownItem = [[NSMenuItem alloc] initWithTitle:@"Markdown File" action:@selector(createNewMarkdownFile:) keyEquivalent:@""];
        newMarkdownItem.image = [self contextMenuImageNamed:@"document"];
        [submenu addItem:newMarkdownItem];
    }

    // Add "New Microsoft Word Document" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureWordDocument]) {
        NSMenuItem *newWordItem = [[NSMenuItem alloc] initWithTitle:@"Microsoft Word Document" action:@selector(createNewWordDocument:) keyEquivalent:@""];
        newWordItem.image = [self contextMenuImageNamed:@"word"];
        [submenu addItem:newWordItem];
    }

    // Add "New Microsoft Excel Spreadsheet" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureExcelSpreadsheet]) {
        NSMenuItem *newExcelItem = [[NSMenuItem alloc] initWithTitle:@"Microsoft Excel Spreadsheet" action:@selector(createNewExcelDocument:) keyEquivalent:@""];
        newExcelItem.image = [self contextMenuImageNamed:@"excel"];
        [submenu addItem:newExcelItem];
    }

    // Add "New Microsoft PowerPoint Presentation" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeaturePowerPointPresentation]) {
        NSMenuItem *newPowerPointItem = [[NSMenuItem alloc] initWithTitle:@"Microsoft PowerPoint Presentation" action:@selector(createNewPowerPointDocument:) keyEquivalent:@""];
        newPowerPointItem.image = [self contextMenuImageNamed:@"powerpoint"];
        [submenu addItem:newPowerPointItem];
    }

    // Add "New Pages Document" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeaturePagesDocument]) {
        NSMenuItem *newPagesItem = [[NSMenuItem alloc] initWithTitle:@"Pages Document" action:@selector(createNewPagesDocument:) keyEquivalent:@""];
        newPagesItem.image = [self contextMenuImageNamed:@"pages"];
        [submenu addItem:newPagesItem];
    }

    // Add "New Numbers Spreadsheet" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureNumbersSpreadsheet]) {
        NSMenuItem *newNumbersItem = [[NSMenuItem alloc] initWithTitle:@"Numbers Spreadsheet" action:@selector(createNewNumbersDocument:) keyEquivalent:@""];
        newNumbersItem.image = [self contextMenuImageNamed:@"numbers"];
        [submenu addItem:newNumbersItem];
    }

    // Add "New Keynote Presentation" to submenu (if enabled)
    if ([self isFeatureEnabled:kFeatureKeynotePresentation]) {
        NSMenuItem *newKeynoteItem = [[NSMenuItem alloc] initWithTitle:@"Keynote Presentation" action:@selector(createNewKeynoteDocument:) keyEquivalent:@""];
        newKeynoteItem.image = [self contextMenuImageNamed:@"keynote"];
        [submenu addItem:newKeynoteItem];
    }

    // If only 1 file type enabled, show it directly instead of a submenu
    if (submenu.numberOfItems == 1) {
        NSMenuItem *original = submenu.itemArray[0];
        NSString *title = [@"New " stringByAppendingString:original.title];
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:title action:original.action keyEquivalent:@""];
        newItem.image = original.image;
        [menu addItem:newItem];
    } else if (submenu.numberOfItems > 1) {
        NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:@"New File" action:nil keyEquivalent:@""];
        mainItem.image = [self contextMenuImageNamed:@"add"];
        mainItem.submenu = submenu;
        [menu addItem:mainItem];
    }

    return menu;
}

// Function to copy current directory path to clipboard
- (void)copyPathToClipboard:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    NSString *path = targetURL.path;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:path forType:NSPasteboardTypeString];

    NSLog(@"Copied path to clipboard: %@", path);
}

// Function to open Terminal at current directory
- (void)openTerminalAtPath:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    NSString *path = targetURL.path;
    NSString *escapedPath = [path stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \"open -a Terminal '%@'\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to open Terminal: %@", errorDict);
    } else {
        NSLog(@"Opened Terminal at: %@", path);
    }
}

// Function to create new Word document
- (void)createNewWordDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");\
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
    // Includes styles.xml for Calibri 11pt default font
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/word/_rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/word/document.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\\\"/><Override PartName=\\\"/word/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"word/document.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/word/_rels/document.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:styles xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after=\\\"0\\\" w:line=\\\"240\\\" w:lineRule=\\\"auto\\\"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type=\\\"paragraph\\\" w:default=\\\"1\\\" w:styleId=\\\"Normal\\\"><w:name w:val=\\\"Normal\\\"/><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:style></w:styles>' > \\\"$TMPDIR/word/styles.xml\\\" && "
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

// Function to create new Excel document
- (void)createNewExcelDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"xlsx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    // Create blank .xlsx using shell script
    // .xlsx is a zip file containing XML files
    // Includes styles.xml for Calibri 11pt default font
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/xl/_rels\\\" \\\"$TMPDIR/xl/worksheets\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/xl/workbook.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\\\"/><Override PartName=\\\"/xl/worksheets/sheet1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\\\"/><Override PartName=\\\"/xl/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"xl/workbook.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><workbook xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><sheets><sheet name=\\\"Sheet1\\\" sheetId=\\\"1\\\" r:id=\\\"rId1\\\"/></sheets></workbook>' > \\\"$TMPDIR/xl/workbook.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\\\" Target=\\\"worksheets/sheet1.xml\\\"/><Relationship Id=\\\"rId2\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/xl/_rels/workbook.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><styleSheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><fonts count=\\\"1\\\"><font><sz val=\\\"11\\\"/><name val=\\\"Calibri\\\"/><family val=\\\"2\\\"/></font></fonts><fills count=\\\"2\\\"><fill><patternFill patternType=\\\"none\\\"/></fill><fill><patternFill patternType=\\\"gray125\\\"/></fill></fills><borders count=\\\"1\\\"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\"/></cellStyleXfs><cellXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\" xfId=\\\"0\\\"/></cellXfs></styleSheet>' > \\\"$TMPDIR/xl/styles.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><worksheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><sheetData/></worksheet>' > \\\"$TMPDIR/xl/worksheets/sheet1.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to create Excel document: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

// Function to create new PowerPoint document
- (void)createNewPowerPointDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"pptx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    // Create blank .pptx using shell script
    // .pptx is a zip file containing XML files
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/ppt/_rels\\\" \\\"$TMPDIR/ppt/slides\\\" \\\"$TMPDIR/ppt/slideLayouts\\\" \\\"$TMPDIR/ppt/slideMasters\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/ppt/presentation.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml\\\"/><Override PartName=\\\"/ppt/slides/slide1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"ppt/presentation.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:presentation xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><p:sldIdLst><p:sldId id=\\\"256\\\" r:id=\\\"rId1\\\"/></p:sldIdLst></p:presentation>' > \\\"$TMPDIR/ppt/presentation.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\\\" Target=\\\"slides/slide1.xml\\\"/></Relationships>' > \\\"$TMPDIR/ppt/_rels/presentation.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:sld xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id=\\\"1\\\" name=\\\"\\\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld></p:sld>' > \\\"$TMPDIR/ppt/slides/slide1.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to create PowerPoint document: %@", errorDict);
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

// Function to create new Numbers document
- (void)createNewNumbersDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"numbers";
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
    NSString *templatePath = [bundle pathForResource:@"Blank" ofType:@"numbers"];

    if (!templatePath) {
        NSLog(@"Failed to find Blank.numbers template in bundle");
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
        NSLog(@"Failed to create Numbers document: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

// Function to create new Keynote document
- (void)createNewKeynoteDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Build unique filename
    NSString *baseName = @"Untitled";
    NSString *extension = @"key";
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
    NSString *templatePath = [bundle pathForResource:@"Blank" ofType:@"key"];

    if (!templatePath) {
        NSLog(@"Failed to find Blank.key template in bundle");
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
        NSLog(@"Failed to create Keynote document: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

// Function to create new text file
- (void)createNewTextFile:(id)sender {
    [self createFileWithExtension:@"txt"];
}

// Function to create new Markdown file
- (void)createNewMarkdownFile:(id)sender {
    [self createFileWithExtension:@"md"];
}

// Helper function to create empty files
- (void)createFileWithExtension:(NSString *)extension {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) {
        NSLog(@"No target URL");
        return;
    }

    // Create filename
    NSString *baseName = @"Untitled";
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
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"touch '%@'\"", escapedPath];

    // Run AppleScript
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed: %@", errorDict);
    } else {
        NSLog(@"Created: %@", filePath);
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

