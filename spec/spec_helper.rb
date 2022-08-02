require 'amazing_print'
require 'dry-inflector'

require_relative '../lib/json-exporter'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # rspec -fd
  # config.formatter = :documentation # :progress, :html, :json, CustomFormatterClass
end

def rr data
  puts '- start: %s - %s' % [data.class, caller[0].sub(__dir__+'/', 'spec/')]
  ap data
  puts '- end'
end
