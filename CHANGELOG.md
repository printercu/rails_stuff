## Unreleased

### Controllers

- `resource_params` returns permited hash when resource key is not present in `params`.
- `use_resource_class_for_invalid_type` option for STI helpers,
  and `RailsStuff::ResourcesController::StiHelpers::InvalidType` error instead of
  `ActiveRecord::NotFound` for invalid type.

### Misc

- Parse BigDecimals with ParamsParser.

## 0.6.0.rc1

### Controllers

- Don't overwrite :location option if present.
- Don't overwrite responder and `respond_with`'s mimes.
- `#current_sort_scope` to access applied sorting rules.
- `.resource_helper` has `source` option, which accepts lambdas and strings.
  `class` option is deprecated now in favour of `source`.

### Models

- Improved Statusable:

  - Model are now clear from lot of helper methods.
    There is single `statuses` method for statusable field which holds all helpers.
  - `.select_options` supports `:only` option.
  - Helpers to map/unmap values for mapped statuses from external code.

### Tests

- A lot of new test and rspec helpers and configs (see RSpecHelpers, TestHelpers).
- `RSpecHelpers.setup` & `TestHelpers.setup` to setup helpers instead of requiring
  files. This methods accepts `only` & `except` options.

### Misc

- Use AR#update instead of #update_attributes.

## 0.5.1

Rails 5 support.

## 0.5.0

### Controllers

- `belongs_to`.
- `resource_helper` generates enquirer method.
- `resources_controller kaminari: false` to skip kaminari for the only controller.
- `has_sort_scope` can use custom order method.
- Fix: removed source_for_collection from action_methods.

### Models

- Statusable supports mappings (store status as integer) and suffixes.
- AssociationWriter to override `#field=` & `#field_id=` in single instruction.
- Limit retries count for RandomUniqAttr (default to 10).

### Helpers

- `Helpers::Translation` methods can raise errors on missing translations.
  It respects app's `raise_on_missing_translations`, and can be configured manually.

### Tests

- Concurrency helper.
- RSpec configurator.

Misc

- RequireNested to require all files in subdirectory.
- `rails g concern %parent%/%module%` generator for concerns.

## 0.4.0

- TypesTracker defines scopes for every type.

## 0.3.0

- PluginManager & media queries.

## 0.2.0

- Bypass block to `respond_with`.

- `url_for_keeping_params`

- `params.require_permitted`
