require 'spec_helper'

###

Company2 = Struct.new(:name, :address)

JsonExporter Company2 do
  prop :name
  prop :address
end

###

describe JsonExporter do
  it 'expects basic export to work' do
    name    = 'ACME 1'
    address = 'Nowhere 123'

    company = Company2.new(name, address)
    result  = JsonExporter.export(company)

    expect(result[:name]).to eq(name)
    expect(result[:address]).to eq(address)
  end
end
