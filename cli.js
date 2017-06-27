#!/usr/bin/env node
var args, i, len, cmdGroups, cmdGroup, options, unit
args = process.argv.slice(2)
options = {
  cwds: [],
  lds: []
}
for (i = 0, len = args.length; i < len; i++) {
  if (args[i][0] === '-') {
    switch (args[i]) {
      case '-u':
      case '--unlink':
        options.unlink = true
        break
      case '-s':
      case '--silent':
        options.silent = true
        break
      case '-v':
      case '--verbose':
        options.verbose = true
        break
      case '-t':
      case '--test':
        options.test = true
        break
      case '-n':
      case '--no-install':
        options.noInstall = true
        break
      case '-p':
      case '--pm':
        options.pm = args[++i]
        break
      case '-l':
      case '--lookup-dir':
        options.lds.push(args[++i])
        break
      case '-h':
      case '--help':
        console.log('usage: linkall [<options>] <folders>')
        console.log('')
        console.log('options:')
        console.log('-p, --pm <cli>      default package manager (defaults to npm)')
        console.log('-n, --no-install    don\'t install uninstalled packages')
        console.log('-l, --look-up <dir> additional dir to lookup local packages')
        console.log('-u, --unlink        unlink local packages and install them directly')
        console.log('-h, --help          output usage information')
        console.log('-s, --silent        suppress output of children')
        console.log('-v, --verbose       additional output')
        console.log('-t, --test          no running only show structure')
        console.log('')
        console.log('folders is optional and defaults to cwd')
        process.exit()
        break
      default:
        console.log('found unrecognized command: ' + args[i])
        console.log('call `linkall --help` to see all available commands\n')

        console.log('exiting...')
        process.exit()
    }
  } else {
    options.cwds.push(args[i])
  }
}
if (options.cwds.length == 0) {
  options.cwds.push(process.cwd())
}
if (!options.pm) {
  options.pm = "npm"
}
close = require('./lib/index.js')(options)
process.on("SIGTERM", function () { close("SIGTERM") })
process.on("SIGINT", function () { close("SIGINT") })
process.on("SIGHUP", function () { close("SIGHUP") })
