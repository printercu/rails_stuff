module RailsStuff
  # Generates writers which apply given transfromer for values.
  module TransformAttrs
    class << self
      def transformations
        @transformations ||= {}
      end

      # Register new transformation with given block.
      #
      #   number_regexp = /\A\d+\z/
      #   RailsStuff::TransformAttrs.register :phone do |val|
      #     if val && val.to_s =~ number_regexp
      #       ActiveSupport::NumberHelper.number_to_phone(val)
      #     else
      #       val
      #     end
      #   end
      def register(name, &block)
        transformations[name] = block
      end

      def fetch_block(ids)
        if ids.is_a?(Array)
          blocks = ids.map { |x| transformations.fetch(x) }
          ->(val) { blocks.reduce(val) { |x, block| block.call(x) } }
        else
          transformations.fetch(ids)
        end
      end
    end

    register(:strip) { |val| val && val.to_s.strip }
    register(:nullify, &:presence)
    register(:strip_and_nullify) { |val| val && val.to_s.strip.presence }

    # Options:
    #
    # - `with` - use built-in transfromers from TransformAttrs.transformations.
    #   Add new transformations with TransformAttrs.register.
    # - `new_module` - create new module for generated methods.
    #   Accepts `:prepend` or `:include`. By default it uses single module
    #   which is prepended.
    #
    #   transform_attrs(:attr1, :attr2) { |x| x.to_s.downcase }
    #   transform_attrs(:attr3, &:presence) # to nullify blanks
    #   transform_attrs(:attr4, with: :strip)
    #   transform_attrs(:attr4, with: [:strip, :nullify])
    #   transform_attrs(:attr5, new_module: :include)
    def transform_attrs(*attrs, with: nil, new_module: false, &block)
      block ||= TransformAttrs.fetch_block(with)
      mod = Module.new.tap { |x| public_send(new_module, x) } if new_module
      mod ||= transform_attrs_methods
      mod.class_eval do
        attrs.each do |attr|
          define_method("#{attr}=") { |val| super(block[val]) }
        end
      end
    end

    # Module to store generated methods, so they can be overriden in model.
    def transform_attrs_methods
      @transform_attrs_methods ||= Module.new.tap { |x| prepend x }
    end
  end
end
