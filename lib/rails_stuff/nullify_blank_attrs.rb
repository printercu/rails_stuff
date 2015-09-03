module RailsStuff
  # Changes to `nil` assigned blank attributes.
  #
  #     class App
  #       nullify_blank_attrs :site_url
  #       # ...
  module NullifyBlankAttrs
    def nullify_blank_attrs(*attrs)
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
