xcodebuild archive -scheme "TruvideoSdkCamera" -destination generic/platform=iOS -archivePath "archives/TruvideoSdkCamera_iOS" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive -scheme "TruvideoSdkCamera" -destination "generic/platform=iOS Simulator" -archivePath "archives/TruvideoSdkCamera_iOS_Simulator" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework -framework archives/TruvideoSdkCamera_iOS.xcarchive/Products/Library/Frameworks/TruvideoSdkCamera.framework -framework archives/TruvideoSdkCamera_iOS_Simulator.xcarchive/Products/Library/Frameworks/TruvideoSdkCamera.framework -output TruvideoSdkCamera.xcframework
