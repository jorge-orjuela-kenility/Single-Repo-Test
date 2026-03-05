//
// Copyright © 2026 TruVideo. All rights reserved.
//

#import "VideoLibraryRegistry.h"

extern void truVideoLibraryRegistry(void);

@implementation VideoLibraryRegistry

+ (void)load {
    truVideoLibraryRegistry();
}

@end
