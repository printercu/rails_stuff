require 'has_scope'

module RailsStuff
  # Provides safe and flexible way to sort collections by user's input.
  # Uses `has_scope` gem.
  #
  # Supports different input format, and limits requested fields
  # to allowed subset.
  module SortScope
    # Register type for has_scop that accepts stings, hashes & arrays.
    HasScope::ALLOWED_TYPES[:any] = [[String, Hash, Array, Symbol]]

    # Setups has_scope to order collection by allowed columns.
    # Sort column is filtered by SortScope.filter_param method.
    # Accepts params:
    #
    # - `sort=name`
    # - `sort=name&sort_desc=true`
    # - `sort[name]&sort[order]`
    # - `sort[name]&sort[order]=desc
    #
    # #### Options
    #
    # - `by` - array of available fields to sort by,
    # - `default` - default sort expression,
    # - `only` - bypassed to `has_scope` to limit actions (default to `:index`),
    # - `order_method` - use custom method to sort instead of `.order`.
    #
    # rubocop:disable ClassVars
    def has_sort_scope(config = {})
      @@_sort_scope_id ||= 0
      default = config[:default] || :id
      allowed = Array.wrap(config[:by]).map(&:to_s)
      only_actions = config.fetch(:only, :index)
      order_method = config.fetch(:order_method, :order)
      # Counter added into scope name to allow to define multiple scopes in same controller.
      has_scope("sort_#{@@_sort_scope_id += 1}",
        as:           :sort,
        default:      nil,
        allow_blank:  true,
        only:         only_actions,
        type:         :any,
      ) do |c, scope, val|
        sort_args = SortScope.filter_param(val, c.params, allowed, default)
        scope.public_send(order_method, sort_args)
      end
    end
    # rubocop:enable ClassVars

    class << self
      # Filters value with whitelist of allowed fields to sort by.
      #
      # rubocop:disable CyclomaticComplexity, PerceivedComplexity, BlockNesting
      def filter_param(val, params, allowed, default = nil)
        val ||= default
        unless val == default
          val =
            if val.is_a?(Hash)
              val.each_with_object({}) do |(key, dir), h|
                h[key] = (dir == 'desc' ? :desc : :asc) if allowed.include?(key)
              end
            else
              allowed.include?(val) ? val : default
            end
        end
        if val && !val.is_a?(Hash)
          val = {val => ParamsParser.parse_boolean(params[:sort_desc]) ? :desc : :asc}
        end
        val
      end
      # rubocop:enable CyclomaticComplexity, PerceivedComplexity, BlockNesting
    end
  end
end
