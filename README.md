## JSON Exporter

Simple to use and extend, versioned, nested objects support, data exporter.

Idea is simple

* params passed to exporter are available via opts hash (with indifferent access)
* response is available as hash (with indifferent access)

### Installation

`gem 'json-exporter'`

### Full example with all featuters annotated

We will do simple real life API json response formater. It needs to prepare values, filter and format the result.

```ruby
class ApiExporter < JsonExporter
  before do
    opts[:full] ||= false
  end

  after do
    if json[:email]
      json[:email] = json[:email].downcase
    end
  end
end

class UserExporter < ApiExporter
  define do
    prop :name
    prop :email

    if opts[:full]
      prop :bio, 'Full user bio: %s' % model.bio
    end
  end
end

# usage and response

User = Struct.new(:name, :email, :bio)
user = User.new 'Dux', 'DUX+baz@foo.bar', 'charming chonker'

# UserExporter.export(user)
# -> {name:'Dux', email: 'dux@foo.bar'

# UserExporter.export(user, full: true)
# -> {name:'Dux', email: 'dux@foo.bar', bio: 'Full user bio: %s' % user.bio
```

### Protected methods and variables

```ruby
opts                      # passed in opts
before                    # run before export, modify opts
after                     # run before export, modify json response
prop or property          # add property to export model
model or @model           # passed in export model
json or @json or response # json response hash direct access
export                    # export other model, quick access
```

### Features in detail

You can read the [rspec test](https://github.com/dux/json-exporter/blob/master/spec/tests/exporter_spec.rb)
and get better insight on look and feel.

```ruby
class JsonExporter
  # gets converted to
  # def before
  #   super
  #   meta[:version] ||= 1
  # end
  before do
    meta[:version] ||= 1
  end

  define Company do
    # copy :name property
    # same as -> prop :name, model.name
    # same as -> json[:name] = model.name
    prop :name

    # export user as creator property
    prop :creator, export(model.user)
  end

  # define exporter for User class,
  # JsonExporter(User)
  # JsonExporter.export(@user)
  # JsonExporter.new(@user).render
  define User do
    # proparty can be called by full name and can execute block
    prop :calc do
      # access passed @model vi @model or model
      # add
      model.num * 4
    end

    # same as - prop :company, export(model.company)
    # you can pass opts too - prop :company, export(model.company, full: true)
    export :company

    # attact full export of model.company as company_full property
    prop :company_full, export(model.company, full: true)

    # add prop only if opts version is 2+
    if opts.version > 2 do
      prop :extra, :value_1
    end
  end
end
```

### Params in details + examples

* model that is exported is available via `@model` or `model`
* predefined methods
  * `property` (or `prop`) - export single property
  * `export` - export full model
  * `json (or response)` - add directly to response hash
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
  # after filter will run after transformation
  after do
    # every object has an ID, export it
    prop :id

    # call custom exporter function
    custom_foo

    # append medtadata
    json[:_meta] = {
      class: model.class.to_s,
      view_path: model.path,
      api_path: model.api_path
    }
  end

  # same as CompanyUser
  define :company_user do
  end

  define User do
    prop :name, model.name.capitalize

    # export
    export :company      # same as "prop :company, export(model.company)"
    export model.company # same if model.company class name is Company

    # you can add directly to response in 3 ways
    # disable this feature with JsonExporter.disable_wia!
    json[:foo]  = @user.foo  # as symbol
    json['foo'] = @user.foo # string
    json.foo    = @user.foo    # method
  end
end
```

### Custom export names

Define multiple exporters, and pipe same object trough multiple exporters to get different results

```ruby
class SomeExporter < JsonExporter
  define :foo_1 do
    # ...
  end

  define :foo_2 do
    # ...
  end
end

SomeExporter.export(@model, exporter: :foo_1)
SomeExporter.export(@model, exporter: :foo_2)
```

## Tips

* If you want to covert hash keys to string keys, for example to use in
  [Liquid templateing](https://shopify.github.io/liquid/), use `@response.stringify_keys`
* If you do not want to use hash with indifferent access for response
  ([https://github.com/dux/hash_wia](https://github.com/dux/hash_wia)), set `JsonExporter.disable_wia!`
