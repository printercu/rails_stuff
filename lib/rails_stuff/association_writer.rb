module RailsStuff
  # ActiveRecord's association can be updated with object and by object id.
  # Owerwrite this both writers with single instruction:
  #
  #   association_writer :product do |val|
  #     super(val).tap { update_price if product }
  #   end
  #
  module AssociationWriter
    def association_writer(name, &block)
      define_method("#{name}=", &block)
      define_method("#{name}_id=", &block)
    end
  end
end
