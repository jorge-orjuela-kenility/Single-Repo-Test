xcodebuild archive -scheme "TruvideoSdk" -destination generic/platform=iOS -archivePath "archives/TruvideoSdk_iOS" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive -scheme "TruvideoSdk" -destination "generic/platform=iOS Simulator" -archivePath "archives/TruvideoSdk_iOS_Simulator" -derivedDataPath "$PWD/derivedData" -clonedSourcePackagesDirPath "$HOME/Library/Developer/Xcode/DerivedData/$XCODE_SCHEME" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework -framework archives/TruvideoSdk_iOS.xcarchive/Products/Library/Frameworks/TruvideoSdk.framework -framework archives/TruvideoSdk_iOS_Simulator.xcarchive/Products/Library/Frameworks/TruvideoSdk.framework -output TruvideoSdk.xcframework
