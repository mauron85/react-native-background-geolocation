module.exports = {
  dependency: {
    platforms: {
      android: {
gu       sourceDir: "./android/lib",
        packageImportPath: "import com.marianhello.bgloc.react.BackgroundGeolocationPackage;",
        packageInstance: "new BackgroundGeolocationPackage()"
      },
      ios: {
        project: "./ios/RCTBackgroundGeolocation.xcodeproj",
        podspecPath: "./ios/@mauron85_react-native-background-geolocation.podspec"
      }
    },
    assets: []
  }
};