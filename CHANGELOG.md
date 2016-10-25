## Unreleased

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
