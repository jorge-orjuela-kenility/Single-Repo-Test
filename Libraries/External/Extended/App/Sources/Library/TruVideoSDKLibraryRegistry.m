//
// Copyright © 2026 TruVideo. All rights reserved.
//

#import "TruVideoSDKLibraryRegistry.h"

extern void truVideoSDKLibraryRegistry(void);

@implementation TruVideoSDKLibraryRegistry

+ (void)load {
    truVideoSDKLibraryRegistry();
}

@end
