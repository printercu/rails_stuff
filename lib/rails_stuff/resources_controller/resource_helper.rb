module RailsStuff
  module ResourcesController
    # Defines resource helper and finder method.
    module ResourceHelper
      class << self
        def deprecation
          @deprecation ||= begin
            require 'active_support/deprecation'
            ActiveSupport::Deprecation.new('0.7', 'RailsStuff')
          end
        end
      end

      # Defines protected helper method. Ex. for `:user`
      #
      #     helper_method :user
      #
      #     def user
      #       @user ||= User.find params[:user_id]
      #     end
      #
      # #### Options
      #
      # - `source` - class name or Proc returning relation, default to `resource_name.classify`.
      # - `param` - param name, default to `resource_name.foreign_key`
      #
      # rubocop:disable CyclomaticComplexity, PerceivedComplexity, AbcSize
      def resource_helper(name, param: nil, source: nil, **options)
        ResourceHelper.deprecation.warn('use :source instead of :class') if options.key?(:class)

        param ||= name.to_s.foreign_key.to_sym
        define_method("#{name}?") { params.key?(param) }

        ivar = :"@#{name}"
        source ||= options[:class] || name.to_s.classify
        if source.is_a?(Proc)
          define_method(name) do
            instance_variable_get(ivar) ||
              instance_variable_set(ivar, instance_exec(&source).find(params[param]))
          end
        else
          source = Object.const_get(source) unless source.is_a?(Class)
          define_method(name) do
            instance_variable_get(ivar) ||
              instance_variable_set(ivar, source.find(params[param]))
          end
        end

        helper_method name, :"#{name}?"
        protected name, :"#{name}?"
      end
      # rubocop:enable CyclomaticComplexity, PerceivedComplexity, AbcSize
    end
  end
end
