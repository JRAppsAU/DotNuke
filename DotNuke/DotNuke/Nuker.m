//
//    The MIT License (MIT)
//
//    Copyright (c) 2015 JR Apps
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

//
//  Nuker.m
//  DotNuke
//
//  Created by Joshua Luongo on 25/06/2015.
//  Copyright (c) 2015 JR Apps. All rights reserved.
//

#import "Nuker.h"

@implementation Nuker

- (NSMutableArray *)getListOfEjectableMedia
{
    NSArray *mountedRemovableMedia = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:NSVolumeEnumerationSkipHiddenVolumes];
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *volURL in mountedRemovableMedia)
    {
        int                 err = 0;
        DADiskRef           disk;
        DASessionRef        session;
        CFDictionaryRef     descDict;
        session = DASessionCreate(NULL);
        if (session == NULL) {
            err = EINVAL;
        }
        if (err == 0) {
            disk = DADiskCreateFromVolumePath(NULL,session,(__bridge CFURLRef)volURL);
            if (session == NULL) {
                err = EINVAL;
            }
        }
        if (err == 0) {
            descDict = DADiskCopyDescription(disk);
            if (descDict == NULL) {
                err = EINVAL;
            }
        }
        if (err == 0) {
            CFTypeRef mediaEjectableKey = CFDictionaryGetValue(descDict,kDADiskDescriptionMediaEjectableKey);
            CFTypeRef deviceProtocolName = CFDictionaryGetValue(descDict,kDADiskDescriptionDeviceProtocolKey);
//            CFTypeRef kindName = CFDictionaryGetValue(descDict, kDADiskDescriptionVolumeKindKey);
            
            if (mediaEjectableKey != NULL)
            {
                BOOL op = CFEqual(mediaEjectableKey, CFSTR("0")) || CFEqual(deviceProtocolName, CFSTR("USB"));
//                BOOL hfs = CFEqual(kindName, CFSTR("hfs"));
                if (op) {
                    [result addObject:volURL];
                }
            }
        }
        if (descDict != NULL) {
            CFRelease(descDict);
        }
        if (disk != NULL) {
            CFRelease(disk);
        }
        if (session != NULL) {
            CFRelease(session);
        }
    }
    return result;
}

- (void)cleanVolume:(NSURL *)path
{
    NSLog(@"Cleaning...");
    
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/sbin/dot_clean";
    task.arguments = @[path.path];
    task.standardOutput = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    
    [task waitUntilExit];
    
    [file closeFile];
    
    
    NSString *dcOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"dot_clean returned:\n%@", dcOutput);
    
    int termStatus = task.terminationStatus;
    
    if (termStatus != 0)
    {
        if ([_delegate respondsToSelector:@selector(cleanFailed:)])
        {
            NSError *err = [NSError errorWithDomain:@"dotnuke" code:task.terminationStatus userInfo:@{
                                                                                                      NSLocalizedDescriptionKey:[NSString stringWithFormat:@"An unknown error occured.\ndot_clean returned: %i.", termStatus]
                                                                                                      }];
            
            [_delegate cleanFailed:err];
        }
    }
    else
    {
        [self ejectVolume:path];
    }
}

- (void)ejectVolume:(NSURL *)path
{
    NSLog(@"Ejecting..");
    NSError *eject = nil;
    BOOL worked = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtURL:path error:&eject];
    
    if (eject)
    {
        if ([_delegate respondsToSelector:@selector(volumeFailedEject:)])
        {
            [_delegate volumeFailedEject:eject];
        }
    }
    else if (worked)
    {
        if ([_delegate respondsToSelector:@selector(volumeEjected:)])
        {
            [_delegate volumeEjected:path.lastPathComponent];
        }
    }
    else
    {
        NSError *err = [NSError errorWithDomain:@"dotnuke" code:500 userInfo:@{NSLocalizedDescriptionKey:@"An unknown error occured."}];
        if ([_delegate respondsToSelector:@selector(volumeFailedEject:)])
        {
            [_delegate volumeFailedEject:err];
        }
    }
}

@end
