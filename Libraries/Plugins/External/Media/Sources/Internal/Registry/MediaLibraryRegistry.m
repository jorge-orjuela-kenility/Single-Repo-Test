//
// Copyright © 2026 TruVideo. All rights reserved.
//

#import "MediaLibraryRegistry.h"

extern void truVideoMediaLibraryRegistry(void);

@implementation MediaLibraryRegistry

+ (void)load {
    truVideoMediaLibraryRegistry();
}

@end
