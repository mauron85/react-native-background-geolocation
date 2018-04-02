const OS = require('os')
const { exec } = require('child_process')

const platform = OS.platform()

if (platform === 'darwin' || platform === 'linux') {
  exec('./scripts/prepublish/script.sh')
} else if (platform === 'win32') {
  exec('scripts\\prepublish\\script.bat')
}
