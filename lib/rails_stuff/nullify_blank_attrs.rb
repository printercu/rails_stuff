require 'active_support/core_ext/object/blank'

module RailsStuff
  # Changes to `nil` assigned blank attributes.
  #
  #     class App
  #       nullify_blank_attrs :site_url
  #       # ...
  module NullifyBlankAttrs
    def nullify_blank_attrs(*attrs)
      RailsStuff.deprecation_07.warn('Use transform_attrs *attrs, with: :nullify')
      nullify_blank_attrs_methods.class_eval do
        attrs.each do |attr|
          define_method("#{attr}=") { |val| super(val.presence) }
        end
      end
    end

    # Module to store generated methods, so they can be overriden in model.
    def nullify_blank_attrs_methods
      @nullify_blank_attrs_methods ||= Module.new.tap { |x| prepend x }
    end
  end
end
