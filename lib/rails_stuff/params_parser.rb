module RailsStuff
  # Provides parsing and type-casting functions.
  # Reraises all ocured errors with Error class, so you can handle it together:
  #
  #     rescue_from RailsStuff::ParamsParser::Error, with: :render_bad_request
  #
  # You can define more parsing methods by extending with this module
  # and using .parse:
  #
  #     # models/params_parser
  #     module ParamsParser
  #       extend RailsStuff::ParamsParser
  #       extend self
  #
  #       def parse_money(val)
  #         parse(val) { your_stuff(val) }
  #       end
  #     end
  #
  module ParamsParser
    # This exceptions is wrapper for any exception occured in parser.
    # Original exception message can be retrieved with `original_message` method.
    class Error < ::StandardError
      attr_reader :original_message, :value

      def initialize(original_message = nil, value = nil)
        message = "Error while parsing: #{value.inspect}"
        @original_message = original_message || message
        @value = value
        super(message)
      end

      # Keeps message when passing instance to `raise`.
      def exception(*)
        self
      end

      # Show original messages in tests.
      def to_s
        "#{super} (#{original_message})"
      end
    end

    extend self

    # Parses value with specified block. Reraises occured error with Error.
    def parse(val, *args, &block)
      parse_not_blank(val, *args, &block)
    rescue => e # rubocop:disable Lint/RescueWithoutErrorClass
      raise Error.new(e.message, val), nil, e.backtrace
    end

    # Parses each value in array with specified block.
    # Returns `nil` if `val` is not an array.
    def parse_array(array, *args, &block)
      return unless array.is_a?(Array)
      parse(array) { array.map { |val| parse_not_blank(val, *args, &block) } }
    end

    # Parses value with given block only when it is not nil.
    # Empty string is converted to nil. Pass `allow_blank: true` to return it as is.
    def parse_not_blank(val, allow_blank: false)
      return if val.nil? || !allow_blank && val.is_a?(String) && val.blank?
      yield(val)
    end

    # :method: parse_int
    # :call-seq: parse_int(val)
    #
    # Parse int value.

    # :method: parse_int_array
    # :call-seq: parse_int_array(val)
    #
    # Parses array of ints. Returns `nil` if `val` is not an array.

    # :method: parse_float
    # :call-seq: parse_float(val)
    #
    # Parse float value.

    # :method: parse_float_array
    # :call-seq: parse_float_array(val)
    #
    # Parses array of floats. Returns `nil` if `val` is not an array.

    # Parsers for generic types, which are implemented with #to_i, #to_f & #to_s
    # methods.
    %w[int float].each do |type|
      block = :"to_#{type[0]}".to_proc

      define_method "parse_#{type}" do |val|
        parse(val, &block)
      end

      define_method "parse_#{type}_array" do |val|
        parse_array(val, &block)
      end
    end

    # Parse string value.
    def parse_string(val)
      parse(val, allow_blank: true, &:to_s)
    end

    # Parses array of strings. Returns `nil` if `val` is not an array.
    def parse_string_array(val)
      parse_array(val, allow_blank: true, &:to_s)
    end

    # Parse decimal value.
    def parse_decimal(val)
      parse(val) { |x| BigDecimal.new(x) }
    end

    # Parses array of decimals. Returns `nil` if `val` is not an array.
    def parse_decimal_array(val)
      parse_array(val) { |x| BigDecimal.new(x) }
    end

    # Parse boolean using ActiveResord's parser.
    def parse_boolean(val)
      parse(val) do
        @boolean_parser ||= boolean_parser
        @boolean_parser[val]
      end
    end

    def boolean_parser
      require 'active_record'
      ar_parser = ActiveRecord::Type::Boolean.new
      if RailsStuff.rails4?
        ->(val) { ar_parser.type_cast_from_user(val) }
      else
        ->(val) { ar_parser.cast(val) }
      end
    end

    # Parse time in current TZ using `Time.parse`.
    def parse_datetime(val)
      parse(val) { Time.zone.parse(val) || raise('Invalid datetime') }
    end

    # Parse JSON string.
    def parse_json(val)
      parse(val) { JSON.parse(val) }
    end
  end
end
