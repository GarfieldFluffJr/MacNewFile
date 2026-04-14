//
//  FinderSync.h
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import <Cocoa/Cocoa.h>
#import <FinderSync/FinderSync.h>

@interface FinderSync : FIFinderSync {
    dispatch_source_t _volumeMonitorSource;
}

@end
