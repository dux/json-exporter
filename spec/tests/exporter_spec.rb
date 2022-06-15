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

class JsonExporter
  before do
    opts[:version] ||= 1
  end

  define :company do
    prop :name
    prop :address
    prop :v_check, :version_one

    if opts.version >= 3
      prop :v_check, :version_three
    end

    if opts.version >= 4
      prop :extra, :spicy
    end

    prop :creator, export(model.user)
  end

  define :generic_name do
    prop :name

    response[:foo] = :bar
  end
end

class JsonExporter
  define User do
    export :company

    prop :v_check, :version_one

    if opts.version == 3
      prop :v_check, :version_three
    end

    prop :name
    prop :email
    prop :is_admin do
      user && user.name.include?('dux') ? true : false
    end
  end
end

# default export after filter
JsonExporter.after do
  prop :foo, :bar

  response[:meta] = {
    class: model.class.to_s
  }
end

class GenericExporter < JsonExporter
  before do
    response[:bhistory] = [:first]
  end

  after do
    response[:ahistory] ||= []
    response[:ahistory].push :parent
  end

  define do
    prop :name

    prop(:calc) { model.num * 3 }
  end
end

class GenericExporterChild < GenericExporter
  before do
    response[:bhistory].push :second
  end

  after do
    response[:ahistory].push :child
  end

  define do
    prop :name
    prop :ahistory, [:start]

    response[:bhistory].push :third

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
    response = JsonExporter.export user, user: user, export_depth: 3

    expect(response[:company][:creator][:company][:name]).to eq('ACME')
  end

  it 'uses after filter' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, user: user, export_depth: 3
    expect(response[:foo]).to eq(:bar)
    expect(response[:meta][:class]).to eq('User')
  end

  it 'uses right versions' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, version: 3
    expect(response[:company][:v_check]).to eq(:version_three)
    expect(response[:company][:extra]).to eq(nil)

    response = JsonExporter.export user, version: 4
    expect(response[:company][:v_check]).to eq(:version_three)
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

    expect(result[:bhistory].join('-')).to eq('first-second-third')
    expect(result[:ahistory].join('-')).to eq('start-parent-child')
  end
end
