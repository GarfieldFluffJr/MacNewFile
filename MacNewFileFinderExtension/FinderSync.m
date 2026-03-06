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
    [FIFinderSyncController defaultController].directoryURLs = [NSSet setWithObject:[NSURL fileURLWithPath:@"/"]];
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
    return [NSImage imageNamed:NSImageNameCaution];
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

// --- Helper method to execute AppleScript safely ---

- (void)executeAppleScript:(NSString *)scriptSource revealFilePath:(NSString *)filePath {
    NSDictionary *errorDict = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    [script executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to execute AppleScript: %@", errorDict);
    } else if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:filePath]]];
    }
}

// --- Office document creation methods ---

- (void)createNewWordDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.docx", baseName]];
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).docx", baseName, counter++]];
    }
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"TMPDIR=$(mktemp -d) && mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/word/_rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/word/document.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\\\"/><Override PartName=\\\"/word/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"word/document.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/word/_rels/document.xml.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:styles xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after=\\\"0\\\" w:line=\\\"240\\\" w:lineRule=\\\"auto\\\"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type=\\\"paragraph\\\" w:default=\\\"1\\\" w:styleId=\\\"Normal\\\"><w:name w:val=\\\"Normal\\\"/><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:style></w:styles>' > \\\"$TMPDIR/word/styles.xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:document xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:body><w:p><w:r><w:t></w:t></w:r></w:p></w:body></w:document>' > \\\"$TMPDIR/word/document.xml\\\" && cd \\\"$TMPDIR\\\" && zip -r '%@' . && rm -rf \\\"$TMPDIR\\\"\"", escapedPath];
    [self executeAppleScript:scriptSource revealFilePath:filePath];
}

- (void)createNewExcelDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xlsx", baseName]];
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).xlsx", baseName, counter++]];
    }
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"TMPDIR=$(mktemp -d) && mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/xl/_rels\\\" \\\"$TMPDIR/xl/worksheets\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/xl/workbook.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\\\"/><Override PartName=\\\"/xl/worksheets/sheet1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\\\"/><Override PartName=\\\"/xl/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"xl/workbook.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><workbook xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><sheets><sheet name=\\\"Sheet1\\\" sheetId=\\\"1\\\" r:id=\\\"rId1\\\"/></sheets></workbook>' > \\\"$TMPDIR/xl/workbook.xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\\\" Target=\\\"worksheets/sheet1.xml\\\"/><Relationship Id=\\\"rId2\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/xl/_rels/workbook.xml.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><styleSheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><fonts count=\\\"1\\\"><font><sz val=\\\"11\\\"/><name val=\\\"Calibri\\\"/><family val=\\\"2\\\"/></font></fonts><fills count=\\\"2\\\"><fill><patternFill patternType=\\\"none\\\"/></fill><fill><patternFill patternType=\\\"gray125\\\"/></fill></fills><borders count=\\\"1\\\"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\"/></cellStyleXfs><cellXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\" xfId=\\\"0\\\"/></cellXfs></styleSheet>' > \\\"$TMPDIR/xl/styles.xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><worksheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><sheetData/></worksheet>' > \\\"$TMPDIR/xl/worksheets/sheet1.xml\\\" && cd \\\"$TMPDIR\\\" && zip -r '%@' . && rm -rf \\\"$TMPDIR\\\"\"", escapedPath];
    [self executeAppleScript:scriptSource revealFilePath:filePath];
}

- (void)createNewPowerPointDocument:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pptx", baseName]];
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).pptx", baseName, counter++]];
    }
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"TMPDIR=$(mktemp -d) && mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/ppt/_rels\\\" \\\"$TMPDIR/ppt/slides\\\" \\\"$TMPDIR/ppt/slideLayouts\\\" \\\"$TMPDIR/ppt/slideMasters\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/ppt/presentation.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml\\\"/><Override PartName=\\\"/ppt/slides/slide1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"ppt/presentation.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:presentation xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><p:sldIdLst><p:sldId id=\\\"256\\\" r:id=\\\"rId1\\\"/></p:sldIdLst></p:presentation>' > \\\"$TMPDIR/ppt/presentation.xml\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\\\" Target=\\\"slides/slide1.xml\\\"/></Relationships>' > \\\"$TMPDIR/ppt/_rels/presentation.xml.rels\\\" && echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:sld xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id=\\\"1\\\" name=\\\"\\\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld></p:sld>' > \\\"$TMPDIR/ppt/slides/slide1.xml\\\" && cd \\\"$TMPDIR\\\" && zip -r '%@' . && rm -rf \\\"$TMPDIR\\\"\"", escapedPath];
    [self executeAppleScript:scriptSource revealFilePath:filePath];
}

// --- Other helper methods ---

- (void)createTemplateFileWithExtension:(NSString *)extension {
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
    if (!templatePath) return;
    
    // Escape paths before using them in shell
    NSString *escapedTemplate = [templatePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"cp -R '%@' '%@'\"", escapedTemplate, escapedPath];
    [self executeAppleScript:scriptSource revealFilePath:filePath];
}

- (void)createFileWithExtension:(NSString *)extension {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;
    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];
    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", baseName, counter++, extension]];
    }
    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"touch '%@'\"", escapedPath];
    [self executeAppleScript:scriptSource revealFilePath:filePath];
}

- (void)createNewTextFile:(id)sender { [self createFileWithExtension:@"txt"]; }
- (void)createNewMarkdownFile:(id)sender { [self createFileWithExtension:@"md"]; }
- (void)createNewPagesDocument:(id)sender { [self createTemplateFileWithExtension:@"pages"]; }
- (void)createNewNumbersDocument:(id)sender { [self createTemplateFileWithExtension:@"numbers"]; }
- (void)createNewKeynoteDocument:(id)sender { [self createTemplateFileWithExtension:@"key"]; }

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
    if (targetURL) {
        NSString *escapedPath = [targetURL.path stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
        NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"open -a Terminal '%@'\"", escapedPath];
        // Do not reveal file here, just open the terminal
        [self executeAppleScript:scriptSource revealFilePath:nil];
    }
}

@end
