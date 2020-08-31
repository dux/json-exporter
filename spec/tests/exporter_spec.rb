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

  prop :creator, export(model.user)
end

JsonExporter.define Company, version: 3 do
  prop :name
  prop :address
  prop :v_check, :v_3

  prop :creator, export(model.user)
end

JsonExporter.define :company, version: 4 do
  copy
  prop :extra, :spicy
end

JsonExporter.define :company_naked do
  prop :name

  response[:foo] = :bar
end

JsonExporter.define :user do
  export :company

  prop :name
  prop :email
  prop :is_admin do
    user && user.name.include?('dux') ? true : false
  end
end

# default export after filter
JsonExporter.filter do
  prop :foo, :bar

  response[:meta] = {
    class: model.class.to_s,
  }
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
    data = JsonExporter.export company, exporter: :company_naked
    expect(data[:address]).to be_nil
    expect(data[:foo]).to be(:bar)
  end

  it 'exports deep if needed' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, user: user, depth: 3
    expect(response.company.creator.company.name).to eq('ACME')
  end

  it 'uses before filter' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, user: user, depth: 3
    expect(response[:foo]).to eq(:bar)
    expect(response[:meta][:class]).to eq('User')
  end

  it 'uses right versions' do
    user     = User.new 'dux', 'dux@net.hr'
    response = JsonExporter.export user, version: 3
    expect(response.company.v_check).to eq(:v_3)
    expect(response.company[:extra]).to eq(nil)

    response = JsonExporter.export user, version: 4
    expect(response.company.v_check).to eq(:v_3)
    expect(response.company[:extra]).to eq(:spicy)
  end
end
