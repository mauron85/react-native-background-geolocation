For development, react-native libs are required provided by react-native package.

1. Install semver package
`npm install semver`

2. Install react-native package

Following command will download and extract react-native package into current directory.
Must be executed from within this (ios) directory:

`./npm_download.sh react-native`

3. Rename Base folder

Done in react-native project `Copy Headers` phase, but since we are not including
react-native project, we have to do this manualy.

`mv react-native/React/Base react-native/React/React`