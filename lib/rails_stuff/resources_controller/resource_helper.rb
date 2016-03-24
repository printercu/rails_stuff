module RailsStuff
  module ResourcesController
    # Defines resource helper and finder method.
    module ResourceHelper
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
      # - `class` - class name, default to `resource_name.classify`
      # - `param` - param name, default to `resource_name.foreign_key`
      def resource_helper(resource_name, **options)
        helper_method resource_name, :"#{resource_name}?"
        resource_name = resource_name.to_s
        class_name = options[:class] || resource_name.classify
        param_key = options[:param] || resource_name.foreign_key

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          protected

          def #{resource_name}
            @#{resource_name} ||= #{class_name}.find(params[:#{param_key}])
          end

          def #{resource_name}?
            params.key?(:#{param_key})
          end
        RUBY
      end
    end
  end
end
