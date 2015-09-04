module RailsStuff
  # Provides save way to generate uniq random values for ActiveRecord models.
  # You need to make field nullable and add unique index on it.
  # The way it works:
  #
  # - Instance is saved as usual
  # - If random fields are not empty, it does nothing
  # - Generates random value and tries to update instance
  # - If `RecordNotUnique` is occured, it keeps trying to generate new values.
  #
  module RandomUniqAttr
    DEFAULT_GENERATOR = ->(*) { SecureRandom.hex(32) }

    class << self
      # Made from `Devise.firendly_token` with increased length.
      def friendly_token(length = 32)
        SecureRandom.urlsafe_base64(length).tr('lIO0', 'sxyz')
      end
    end

    # Generates necessary methods and setups on-create callback for the `field`.
    # You can optionally pass custom generator function:
    #
    #     random_uniq_attr(:code) { |instance| my_random(instance) }
    #
    def random_uniq_attr(field, &block)
      set_method = :"set_#{field}"
      generate_method = :"generate_#{field}"

      after_create set_method, unless: :"#{field}?"

      # def self.generate_key
      define_singleton_method generate_method, &(block || DEFAULT_GENERATOR)

      # def set_key
      define_method(set_method) do
        begin
          raise 'Available only for persisted record' unless persisted?
          transaction(requires_new: true) do
            update_column field, self.class.send(generate_method, self)
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end
    end
  end
end
