## JSON Exporter

Simple to use and extend, versioned, nested objects support, data exporter.

### Installation

`gem 'json-exporter'`

### Look and feel

You can read the [rspec test](https://github.com/dux/json-exporter/blob/master/spec/tests/exporter_spec.rb)
and get better insight on look and feel.

```ruby
# to define exporter for Company class
class JsonExporter
  define Company do
    # copy :name property
    # same as - response[:name] = model.name
    prop :name
    prop :address

    # export user as creator property
    prop :creator, export(model.user)
  end

  # define exporter for User class
  define User do
    # same as - prop :company, export(model.company)
    export :company

    prop :name
    prop :email

    prop :calc do
      # access passed @model vi @model or model
      model.num * 4
    end

    # add only to version 3+
    version 3 do
      prop :extra, :value_1
    end

    # is current user name dux?
    prop :only_for_dux do
      user && user.name.include?('dux') ? 'Only for dux' : nil
    end

    meta :foo do
      # run only if meta[:foo] is truthy
    end
  end
end

# to export
JsonExporter.export @company,
  user: Current.user,      # defnied @user for exporter
  version: 2,              # define version against you want to export (default 1)
  depth: 2,                # how deep do you want nesting to go (2 default)
  compact: true,           # remove keys with null values, default false
  wia: true,               # allow meta and response access as hash with indifferent accecss, deafult false
  meta: { ip: request.ip } # pass meta info

# Example export
{
  name: "ACME",
  address: "Somewhere 1",
  creator: {
    name: "Dux",
    email: "foo@bar.baz"
  }
}
```

### Params in details + examples

* model that is exported is available via `@model` or `model`
* current user (if provided) is available as `@user` or `user`. You can export date based on a user
* predefined methods
  * `property` (or `prop`) - export single property
  * `export` - export model
  * `response` - add directly to response
  * `version` - get current version or execute block
* class method `filter` will define filter for all objects. Useful to add metadata to all objects

```ruby
class JsonExporter
  # define custom exporter function
  def custom_foo
    if model.respond_to?(:baz)
      param :baz
    end
  end

  # add id and _meta property to all exported objects
  # filter will run after transformation
  filter do
    # every object has an ID, export it
    prop :id

    # call custom exporter function
    custom_foo

    response[:_meta] = {
      class: model.class.to_s,
      view_path: model.path,
      api_path: model.api_path
    }
  end

  define :company_user do
    # same as CompanyUser
  end

  define User do
    prop :name, model.name.capitalize

    # proparty can be called by full name and can execute block
    property :email do
      model.email.downcase
    end

    # user is passed as user: @user attribute
    # is current user name dux?
    if user && user.name.include?('dux')
      prop :only_for_dux, mode.secret
    end

    # export
    export :company      # same as "prop :company, export(model.company)"
    export model.company # same if model.company class name is Company

    # you can add directly to response
    response[:foo] = @user.foo

    # works if wia: true is passed
    response.foo = @user.foo
    response['foo'] = @user.foo
  end
end

# define custom exporter and use as
# CustomExporter.export(@model)
class CustomExporter < JsonExporter
  before do
    # this runs first
  end

  after do
    # this runs after params export
  end
def

class ChidExporter < CustomExporter
  after do
    # this runs after params export
  end
def

JsonExporter.export @user # no new_stuff
JsonExporter.export @user, # new_stuff!
  version: 2,
  user: User.current
```

## Tips

* If you want to covert hash keys to string keys, for example to use in [Liquid templateing](https://shopify.github.io/liquid/), use `@response.stringify_keys`
* If you want to use coverted hash in code, you can covert it to hash with indifferent access, using `JsonExporter.export(@model, wia: true)`
* Hash with indifferent access module in use is this one: [https://github.com/dux/hash_wia](https://github.com/dux/hash_wia)
