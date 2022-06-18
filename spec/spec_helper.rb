require 'amazing_print'
require 'dry-inflector'

require_relative '../lib/json-exporter'

class Object
  INFLECTOR = Dry::Inflector.new

  %w(classify underscore).each do |el|
    define_method el do
      INFLECTOR.send el, self
    end
  end
end

# basic config
RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # rspec -fd
  # config.formatter = :documentation # :progress, :html, :json, CustomFormatterClass
end
