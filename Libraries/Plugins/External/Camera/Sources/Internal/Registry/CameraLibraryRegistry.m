//
// Copyright © 2025 TruVideo. All rights reserved.
//

#import "CameraLibraryRegistry.h"

extern void truVideoCameraLibraryRegistry(void);

@implementation CameraLibraryRegistry

+ (void)load {
    truVideoCameraLibraryRegistry();
}

@end
