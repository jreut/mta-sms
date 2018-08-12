$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'app'

run App.freeze.app
