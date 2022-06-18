require 'spec_helper'

class FooCustomExporter < JsonExporter
  define :export_2 do
    prop :num, model.sum * 2
  end

  define :export_4 do
    prop :num, model.sum * 4
  end
end

class BarExporter < JsonExporter
  define do
    prop :sum
  end
end

###

describe FooCustomExporter do
  let!(:model) { Struct.new(:sum).new(2) }

  it 'expects 2' do
    export = FooCustomExporter.export(model, exporter: :export_2)
    expect(export[:num]).to eq(4)
  end

  it 'expects 4' do
    export = FooCustomExporter.export(model, exporter: 'Export4')
    expect(export[:num]).to eq(8)
  end

  it 'expects 2' do
    export = BarExporter.export(model)
    expect(export[:sum]).to eq(2)
  end
end