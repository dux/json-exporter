require 'spec_helper'

###

Company = Struct.new(:name, :address) do
  def creator
    User.new('dux', 'dux@.net.hr')
  end

  def user
    User.new('dux', 'dux@.net.hr')
  end
end

User = Struct.new(:name, :email) do
  def company
    Company.new('ACME', 'Nowhere 123')
  end
end

JsonExporter.define :company do
  prop :name
  prop :address
  prop :v_check, :v_1

  version 3 do
    prop :v_check, :v_3
  end

  if version >= 4
    prop :extra, :spicy
  end

  prop :creator, export(model.user)
end

JsonExporter.define :generic_name do
  prop :name

  response[:foo] = :bar
end

class JsonExporter
  define User do
    export :company

    prop :v_check, :v_1

    version 3 do
      prop :v_check, :v_3
    end

    prop :name
    prop :email
    prop :is_admin do
      user && user.name.include?('dux') ? true : false
    end
  end
end

# default export after filter
JsonExporter.filter do
  prop :foo, :bar

  response[:meta] = {
    class: model.class.to_s,
  }
end

class GenericExporter < JsonExporter
  filter do
    response[:history] ||= []
    response[:history].push :parent
  end

  define do
    prop :name

    prop(:calc) { model.num * 3 }
  end
end

class GenericExporterChild < GenericExporter
  filter do
    response[:history].push :child
  end

  define do
    prop :name
    prop :history, [:start]

    prop(:calc) { model.num * 3 }
  end
end

###

describe JsonExporter do
  it 'expects basic export to work' do
    name    = 'ACME 1'
    address = 'Nowhere 123'

    company = Company.new(name, address)
    result  = JsonExporter.export(company)

    expect(result[:name]).to eq(name)
    expect(result[:address]).to eq(address)
  end

  it 'exports complex object' do
    some_user = User.new 'dux', 'dux@net.hr'
    response  = JsonExporter.export some_user, user: some_user
    expect(response[:is_admin]).to eq(true)

    user     = User.new 'dino', 'dux@net.hr'
    response = JsonExporter.export user, user: user
    expect(response[:is_admin]).to eq(false)
  end

  it 'exports naked object' do
    company = Company.new 'ACME 1', 'Nowhere 123'
    data = JsonExporter.export company, exporter: :generic_name
    expect(data[:address]).to be_nil
    expect(data[:foo]).to be(:bar)
  end

  it 'exports deep if needed' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, user: user, depth: 3
    expect(response[:company][:creator][:company][:name]).to eq('ACME')
  end

  it 'uses after filter' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, user: user, depth: 3
    expect(response[:foo]).to eq(:bar)
    expect(response[:meta][:class]).to eq('User')
  end

  it 'uses right versions' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, version: 3
    expect(response[:company][:v_check]).to eq(:v_3)
    expect(response[:company][:extra]).to eq(nil)

    response = JsonExporter.export user, version: 4
    expect(response[:company][:v_check]).to eq(:v_3)
    expect(response[:company][:extra]).to eq(:spicy)
  end

  it 'exports via generic exporter' do
    data   = HashWia.new({ name: 'foo', surname: 'bar', num: 5 })
    result = GenericExporter.export data
    expect(result[:calc]).to eq(15)
  end

  it 'applies filters as it should' do
    data   = HashWia.new({ name: 'dux', num: 1 })
    result = GenericExporterChild.export data
    expect(result[:history].join('-')).to eq('start-parent-child')
  end
end
