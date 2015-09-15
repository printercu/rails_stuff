# RailsStuff
[![Gem Version](https://badge.fury.io/rb/rails_stuff.svg)](http://badge.fury.io/rb/rails_stuff)
[![Code Climate](https://codeclimate.com/github/printercu/rails_stuff/badges/gpa.svg)](https://codeclimate.com/github/printercu/rails_stuff)
[![Build Status](https://travis-ci.org/printercu/rails_stuff.svg)](https://travis-ci.org/printercu/rails_stuff)

Collection of useful modules for Rails.

#### Controllers:

- __[ResourcesController](#resourcescontroller)__
  DRY! Keep your controllers clean.
- __[SortScope](#sortscope)__
  Helper for `has_scope` to sort collections safely.

#### Models:

- __[NullifyBlankAttrs](#nullifyblankattrs)__
  Proxies writers to replace empty values with `nil`.
- __[RandomUniqAttr](#randomuniqattr)__
  You generate random values for attributes, it'll ensure they are uniq.
- __[Statusable](#statusable)__
  `ActiveRecord::Enum` with more features.
- __[TypesTracker](#typestracker)__
  Advanced descendants tracker.

#### Misc:

- __[ParamsParser](#paramsparser)__
  Type-cast params outside of `ActiveRecord`.
- __[RedisStorage](#redisstorage)__
  Simple way to store collections in key-value storage. With scoping and
  key generation.
- __[StrongParameters](#strongparameters)__
  `require_permitted` helper.

#### Helpers:

- __TranslationHelper__
  `translate_action`, `translate_confirmation` helpers to translate
  action names and confirmations in the same way all over you app.
- __LinksHelper__
  Keep your links for basic actions consistent.
- __Bootstrap__
  For bootstrap-formatted flash messages.
- __Forms__
  `hidden_params_fields` to bypass query params in GET-forms.

__[Helpers usage](#helpers)__

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_stuff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_stuff

## Usage

All modules are lazy loaded, so it's ok to require whole gem at once.
There is railtie which will include some of modules into `ActiveRecord::Base`
and `ActionController::Base` by default. You can disable this behavior in
initializer:

```ruby
# Disable auto-setup:
RailsStuff.load_modules = []

# Enable particular modules:
RailsStuff.load_modules = %i(sort_scope statusable)
```

You can override base classes for controller/model with `.base_controller=`,
`.base_model=`.

Works only with ruby 2.0+, tested with Rails 4.2.

There can be lack of documentation in README. Please navigate to module and
check docs & code (press `t` on github) if you miss something.

### ResourcesController

Similar to [InheriteResource](https://github.com/josevalim/inherited_resources)
but much simpler. It adds implementations for basic actions and
accessors for collection and resource. There is no options for almost everything,
but it's easy to extend.

It's main purpose is to ged rid of `@user ||= User.find params[:id]`, and keep
controllers clean:

```ruby
class ApplicationController < ActionController::Base
  extend RailsStuff::ResourcesController # when using without railtie
end

class UsersController < ApplicationController
  resources_controller
  permit_attrs :name, :email
end

class ProjectsController < ApplicationController
  resources_controller sti: true,
    after_save_action: :index,
    source_relation: -> { user.projects }
  resource_helper :user
  permit_attrs :name
  permit_attrs_for Project::External, :company
  permit_attrs_for Project::Internal, :department
end
```

There is built-in support for pagination with Kaminari.
It's enabled automatically if `kaminari` gem is loaded.

Currently depends on `gem 'responders', '> 2.0'`.

### SortScope

```ruby
# in controller
extend RailsStuff::SortScope # when using without railtie

sort_scope by: [:name, :created_at, :balance], default: [:name]

# this scope will accept
#   - `sort=name`
#   - `sort=name&sort_desc=true`
#   - `sort[name]&sort[created_at]`
#   - `sort[name]&sort[created_at]=desc
```

Requires `gem 'has_scope'`.

### NullifyBlankAttrs

Defines proxies for writers to replace empty values with `nil`.

```ruby
# in model
extend RailsStuff::NullifyBlankAttrs # when using without railtie

nullify_blank_attrs :email, :title
```

### RandomUniqAttr

Uses database's UNIQUE constraints and transactions to generate uniq random values.
You need to make field nullable and add unique index on it.
The way it works:

- Instance is saved as usual
- If random fields are not empty, it does nothing
- Generates random value and tries to update instance
- If `RecordNotUnique` is occurred, it keeps trying to generate new values.

```ruby
# in model
extend RailsStuff::RandomUniqAttr # when using without railtie

# Uses DEFAULT_GENERATOR which is SecureRandom(32)
random_uniq_attr :token

# Uses custom generator, which takes template from settings
random_uniq_attr(:code) do |instance|
  MyGenerator.generate(instance.parent.code_template)
end
```

### Statusable

```ruby
class User < ActiveRecord::Base
  extend RailsStuff::RandomUniqAttr # when using without railtie

  STATUSES = %i(confirmed banned)
  has_status_field # uses #status field and STATUSES as values

  # Or pass everything explicitly
  has_status_field :subscription_status, %i(expired active), prefix: :subs_
  # :prefix is used for methods that are build
end

user = User.first

# And you get:
# Scopes
User.confirmed.subs_active
User.not_banned.not_subs_expired
# Useful with has_scope
User.with_status(param[:status]).with_subscription_status(params[:subs_status])

# Translation & select helpers (requires activemodel_translation gem)
User.status_name(:active)
user.subscription_status_name # translates current status
User.status_select_options
User.subscription_status_select_options except: [:expired]

# Accessors
user.status = 'confirmed' or user.confirmed!
user.status_sym # :confirmed
user.subscription_status = :active or user.subs_active!
user.subscription_status # 'active'
user.banned? or user.subs_expired?

# ... and inclusion validator
```

### TypesTracker

```ruby
class Project
  extend RailsStuff::TypesTracker
  # you can also override default list class (Array) with:
  self.types_list_class = FilterableArray
  # smth ...

  # If you want to show all available descendants in development
  # (ex. in dropdown/select), you definitely want this:
  eager_load_types! # will load all files in app/models/project
  # or pass folder explicitly:
  eager_load_types!('lib/path/to/projects')
end

class Project::Big < Project
  unregister_type # remove this class from types_list

  # Or add options for custom list.
  # Following will call types_list.add Project::Big, :arg, option: :example
  register_type :arg, option: :example
end

class Project::Internal < Project::Big; end
class Project::External < Project::Big; end
class Project::Small < Project; end

Project.types_list # [Internal, External, Small]
```

### ParamsParser

Have you missed type-casting outside of `ActiveRecord::Base`? Here is it:

```ruby
ParamsParser.parse_int(params[:field]) # _float, _string, _boolean, _datetime
ParamsParser.parse_int_array(params[:field_with_array])
ParamsParser.parse_json(json_string)

# There is basic .parse method. It runs block only if input is not nil
# and reraises all errors with ParamsParser::Error
ParamsParser.parse(input) { |x| this_can_raise_exception(x) }

# So you can handle all errors in controller with
rescue_from ParamsParser::Error, with: -> { head :bad_request }
```

### RedisStorage

Simple module to organize data in key-value store. Uses `ConnectionPool`
and works good in multi-threaded environments.
Best used with [PooledRedis](https://github.com/printercu/pooled_redis).

```ruby
class Model
  extend RailsStuff::SedisStorage

  self.redis_prefix = :other_prefix # default to underscored model name

  # override .dump, .load for custom serialization. Default to Marshal

  # It uses Rails.redis_pool by default. Override it with
  self.redis_pool = ConnectionPool.new { Redis.new(my_options) }
end

Model.get('key') # GET other_prefix:key
Model.get(['composite', 'key']) # GET other_prefix:composite:key
# .delete works the same way

Model.set('key', data) or Model.set(['composite', 'key'], data)
next_id = Model.set(nil, data) # auto-incremented per-model id
next_id = Model.set(['composite', nil], data) # auto-incremented per-scope id
Model.set(id, data, ex: 10) # pass options for redis
# Or set per-model options for all .set requests:
Model.redis_set_options = {ex: 10}

# generate ids:
Model.next_id or Model.next_id(['composite', 'scope'])
Model.reset_id_seq or Model.reset_id_seq(['composite', 'scope'])
```

### StrongParameters

`#require_permitted` ensures that required values are scalar:

```ruby
params.require_permitted(:access_token, :refresh_token)
# instead of
params.permit(:access_token, :refresh_token).require(:access_token, :refresh_token)
```

### Helpers

Include helper module into `ApplicationHelper`.
Or use `RailsStuff::Helpers::All` to include all helpers together.

Add this sections to your translations ymls:

```yml
helpers:
  actions:
    edit: Change
    delete: Forget about it
  confirm: Really?
  confirmations:
    delete: Will you miss it?
```

And use helpers:

```ruby
translate_action(:edit) or translate_action(:delete)
link_to 'x', url_for(resource),
  method: :delete, data: {confirm:  translate_confirmation(:delete)}
translate_confirmation(:purge_all) # Fallback to default: 'Really?'

# There are helpers for basic links, take a look on helpers/links.rb to know
# how to tune it:
link_to_edit or link_to_edit('url') or link_to_edit([:scope, resource])
link_to_destroy or link_to_destroy('url') or link_to_destroy([:scope, resource])
```

Translation helpers are cached, so there is no need to cache it by yourself in
template if you want to decrease computations. And be aware of it if you
switch locales while rendering single view.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release` to create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/printercu/rails_stuff/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Implement your feature:
  - Write failing spec for your feature
  - Write code
  - Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
