require 'rails/railtie'

module RailsStuff
  MODULES = { # rubocop:disable MutableConstant
    require_nested:       [:require, -> { RequireNested.setup }],
    nullify_blank_attrs:  :model,
    random_uniq_attr:     :model,
    statusable:           :model,
    resources_controller: [
      :controller,
      -> { ResourcesController.use_kaminari! if defined?(::Kaminari) },
    ],
    sort_scope: -> { defined?(::HasScope) && :controller },
    strong_parameters: -> { defined?(ActionController::Parameters) && :require },
    url_for_keeping_params: -> { defined?(ActionDispatch::Routing) && :require },
  }

  class << self
    # Set it to array of modules to load.
    #
    #     # config/initializers/rails_stuff.rb
    #     RailsStuff.load_modules = [:statusable, :sort_scope]
    attr_accessor :load_modules
    # Override default base classes for models & controllers.
    attr_writer :base_controller, :base_model

    def base_controller
      @base_controller || ActionController::Base
    end

    def base_model
      @base_model || ActiveRecord::Base
    end

    # Extends base controller and model classes with modules.
    # By default uses all modules. Use load_modules= to override this list.
    def setup_modules!
      modules_to_load = load_modules || MODULES.keys
      MODULES.slice(*modules_to_load).each do |m, (type, init)|
        case type.respond_to?(:call) ? type.call : type
        when :controller
          RailsStuff.base_controller.extend const_get(m.to_s.camelize)
        when :model
          RailsStuff.base_model.extend const_get(m.to_s.camelize)
        when :require
          require "rails_stuff/#{m}"
        end
        init.try!(:call)
      end
    end
  end

  class Engine < Rails::Engine
    initializer :rails_stuff_setup_modules, after: :load_config_initializers do
      RailsStuff.setup_modules!
    end
  end
end
