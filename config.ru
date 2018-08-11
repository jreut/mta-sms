$LOAD_PATH.unshift __dir__

require 'app'

run App.freeze.app
