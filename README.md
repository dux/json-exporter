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
  before do
    meta[:version] ||= 1
  end

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
    # same as prop :name, model.name
    prop :name

    prop :calc do
      # access passed @model vi @model or model
      model.num * 4
    end

    # same as - prop :company, export(model.company)
    export :company

    # attact full export of model.company as company_full property
    prop :company_full, export(model.company, full: true)

    # add only to version 3+
    if meta.version > 2 do
      prop :extra, :value_1
    end

    # is current user name dux?
    prop :only_for_dux do
      meta.user && meta.user.name.include?('dux') ? 'Only for dux' : nil
    end
  end
end

# example, to export
JsonExporter.export(@company, {
  user: Current.user,      # defnies current user for exporter, export based on user privileges
  full: true,              # define that you want full object, not just
  exporter_depth: 2        # how deep do you want nesting to go in case of recursive export (default 2)
})

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
* current user (if provided via :user param) is available as `@user` or `user`. You can export date based on a user
* predefined methods
  * `property` (or `prop`) - export single property
  * `export` - export full model
  * `response` - add directly to response hash
* class block `before` will define before filter for all objects. Useful to prepare opts before rendering
* class block `after` will define after filter for all objects. Useful to add metadata to all objects

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

    # you can add directly to response in any way
    response[:foo] = @user.foo
    response['foo'] = @user.foo
    response.foo = @user.foo
  end
end
```

### Params in details + examples

Custom Export classes, class inheritance + bofore and after filters

```ruby
# define custom exporter and use as
# CustomExporter.export(@model)
class CustomExporter < JsonExporter
  before do
    # this runs first
    response[:foo] = [1]
  end

  after do
    response[:foo] = response[:foo].join('-')
  end
def

class ChidExporter < CustomExporter
  before do
    response[:foo].push = 2
  end

  define do
    prop :name

    # once defined, params in opts and response can be accessed as method names
    response.foo.push 3
  end
def

ChidExporter.export({name: 'Dux'}) # before -> define -> aftetr -> render json
{
  name: 'Dux',
  foo: '1-2-3'
}
```

## Tips

* If you want to covert hash keys to string keys, for example to use in
  [Liquid templateing](https://shopify.github.io/liquid/), use `@response.stringify_keys`
* If you do not want to use hash with indifferent access for response
  ([https://github.com/dux/hash_wia](https://github.com/dux/hash_wia)), set `JsonExporter.disable_wia!`
