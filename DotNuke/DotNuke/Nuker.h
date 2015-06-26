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
//  Nuker.h
//  DotNuke
//
//  Created by Joshua Luongo on 25/06/2015.
//  Copyright (c) 2015 JR Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
@import DiskArbitration;
@import Cocoa;

@protocol NukerDelegate <NSObject>

@required;
- (void)cleanFailed:(NSError *)err;
- (void)volumeEjected:(NSString *)volName;
- (void)volumeFailedEject:(NSError *)err;

@end

@interface Nuker : NSObject

@property (nonatomic, weak) id<NukerDelegate> delegate;

- (NSMutableArray *)getListOfEjectableMedia;
- (void)cleanVolume:(NSURL *)path;
- (void)ejectVolume:(NSURL *)path;

@end
