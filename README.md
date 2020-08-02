## ApiExporter

Simple to use and extend, versioned, api data exporter.

## Look and feel

```ruby
# to define exporter for Company class
class ApiExporter
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

    # is current user name dux?
    prop :only_for_dux do
      user && user.name.include?('dux') ? 'Only for dux' : nil
    end
  end
end

# to export
ApiExporter.export @company,
  user: Current.user, # defnied @user for exporter
  version: 3,         # define version against you want to export (default 1)
  depth: 2            # how deep do you want nesting to go (2 default)

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

## Params in details with exampels

* model that is exported is available via `@model` or `model`
* current user (if provided) is available as `@user` or `user`. You can export date based on a user
* predefined methods
  * `property` (or prop) - export single property
  * `export` - export model
* advanded predefined methods
  * `response` - add directly to response
  * `copy` - copy properties from lesser version of exporter
* class method `filter` will define filter for all objects. Useful to add metadata to all objects

```ruby
class ApiExporter
  # define custom exporter function
  def custom_foo
    if model.respond_to?(:baz)
      param :baz
    end
  end

  # add id and _meta property to all exported objects
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

  define User do
    prop :name, model.name.capitalize

    # proparty can be called by full name and can execute block
    property :email do
      model.email.downcase
    end

    # is current user name dux?
    if user && user.name.include?('dux')
      prop :only_for_dux, mode.secret
    end

    # export
    export :company      # same as "prop :company, export(model.company)"
    export model.company # same

    # you can add directly to response
    response[:foo] = @user.foo

    # same thing, response hash is key indifferent hash (gem hash_wia)
    # works for props as well
    response['foo'] = @user.foo
  end

  # this will define version 2 of User exporter
  define User, version: 2 do
    # this will copy all attributes from version 1
    copy 1

    prop :new_stuff, @model.v_2_specific
  end
end

ApiExporter.export @user # no new_stuff
ApiExporter.export @user, # new_stuff!
  version: 2,
  user: User.current
``
