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
//  AppDelegate.m
//  DotNuke
//
//  Created by Joshua Luongo on 5/05/2015.
//  Copyright (c) 2015 JR Apps. All rights reserved.
//

#import "AppDelegate.h"
@import ServiceManagement;

@interface AppDelegate () <NSMenuDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic) NSMutableArray *driveList;

@property (nonatomic, strong) Nuker *nuker;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _nuker = [Nuker new];
    [_nuker setDelegate:self];
    
    if ([self willStartAtLogin:[self appURL]]) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"hasAskedAboutLogin"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasAskedAboutLogin"])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Open on Login" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"Do you want DotNuke to open at login."];
        
        NSModalResponse resp = [alert runModal];
        
        if (resp == 1) {
            [self setStartAtLogin:[self appURL] enabled:true];
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"hasAskedAboutLogin"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)awakeFromNib
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    _menu = [[NSMenu alloc] init];
    [_menu setDelegate:self];
    
    NSImage *icon = [NSImage imageNamed:@"MenuIcon"];
    [icon setTemplate:true];
    
    [[self statusItem] setImage:icon];
    [[self statusItem] setMenu:[self menu]];
    [[self statusItem] setHighlightMode:YES];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [self generateList];
    [[self statusItem] setMenu:[self menu]];
}

- (void)generateList
{
    [_menu removeAllItems];
    
    _driveList = [_nuker getListOfEjectableMedia];
    
    if (_driveList.count > 0)
    {
        NSMenuItem *title = [[NSMenuItem alloc] init];
        
        [title setTitle:@"Connected Drives"];
        
        [title setEnabled:NO];
        
        [_menu addItem:title];
        
        for (int i = 0; i < _driveList.count; i++)
        {
            NSURL *url = _driveList[i];
                        
            NSString *volume = [url.lastPathComponent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:url.path];

            [icon setSize:NSMakeSize(32, 32)];
            
            NSMenuItem *hdd = [[NSMenuItem alloc] initWithTitle:[@"  " stringByAppendingString:volume] action:@selector(menuAction:) keyEquivalent:[NSString stringWithFormat:@"drive-%@", url.absoluteString]];
            
            [hdd setImage:icon];
            [hdd setTag:i];
            [hdd setEnabled:true];
            
            [_menu addItem:hdd];
        }
    }
    else
    {
        NSMenuItem *noDrives = [[NSMenuItem alloc] initWithTitle:@"No External Drives" action:nil keyEquivalent:@"title"];
        [noDrives setEnabled:NO];
        
        [_menu addItem:noDrives];
    }
    
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(menuAction:) keyEquivalent:@"quit"];
    NSMenuItem *about = [[NSMenuItem alloc] initWithTitle:@"About" action:@selector(menuAction:) keyEquivalent:@"about"];
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItem:about];
    [_menu addItem:quit];
}

- (IBAction)menuAction:(NSMenuItem *)sender
{
    if ([sender.keyEquivalent isEqualToString:@"quit"])
    {
        [[NSApplication sharedApplication] terminate:0];
    }
    else if ([sender.keyEquivalent isEqualToString:@"about"])
    {
        [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
    }
    else
    {
        NSURL *path = _driveList[sender.tag];
        NSLog(@"User chose: %@", path.absoluteString);
        [_nuker cleanVolume:path];
    }
}

#pragma mark - Start At Login
- (BOOL)willStartAtLogin:(NSURL *)itemURL
{
    Boolean foundIt=false;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seed));
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, NULL);
            if (err == noErr) {
                foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
                CFRelease(URL);
                
                if (foundIt)
                    break;
            }
        }
        CFRelease(loginItems);
    }
    return (BOOL)foundIt;
}

- (void)setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled
{
    LSSharedFileListItemRef existingItem = NULL;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seed));
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, NULL);
            if (err == noErr) {
                Boolean foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
                CFRelease(URL);
                
                if (foundIt) {
                    existingItem = item;
                    break;
                }
            }
        }
        
        if (enabled && (existingItem == NULL)) {
            LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                          NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
            
        } else if (!enabled && (existingItem != NULL))
            LSSharedFileListItemRemove(loginItems, existingItem);
        
        CFRelease(loginItems);
    }       
}

- (NSURL *)appURL
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

#pragma mark - Nuker Delegate
- (void)cleanFailed:(NSError *)err
{
    NSAlert *alert = [NSAlert alertWithError:err];
    [alert runModal];
}

- (void)volumeEjected:(NSString *)volName
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"DotNuke";
    notification.informativeText = [NSString stringWithFormat:@"'%@' was cleaned and ejected!", volName];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)volumeFailedEject:(NSError *)err
{
    NSAlert *alert = [NSAlert alertWithError:err];
    [alert runModal];
}

@end
