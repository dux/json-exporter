require 'spec_helper'

class CustomExporter < JsonExporter
  before do
    # this runs first
    response[:foo] = [1]
  end

  after do
    # ap response[:foo]
    response[:foo] = response[:foo].join('-')
  end
end

class ChildExporter < CustomExporter
  before do
    response[:foo].push 2
  end

  define do
    prop :name

    # once defined, params in opts and response can be accessed as method names
    response.foo.push 3
  end
end

###

describe JsonExporter do
  it 'expects as expected' do
    model  = Struct.new(:name).new('Dux')
    export = ChildExporter.export(model)
    expect(export).to eq({name:'Dux', foo: '1-2-3'})
  end
end