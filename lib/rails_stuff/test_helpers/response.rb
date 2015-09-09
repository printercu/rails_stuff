require 'hashie'

module RailsStuff
  module TestHelpers
    module Response
      class << self
        # Return `Hashie::Mash` for a given object. When `Array` is given
        # it is mapped to mash recursievly.
        def prepare_json_object(object)
          case object
          when Hash then Hashie::Mash.new(object)
          when Array then object.map(&method(__callee__))
          else object
          end
        end
      end

      # Easy access to json bodies. It parses and return `Hashie::Mash`'es, so
      # properties can be accessed via method calls:
      #
      #     response.json_body.order.items.id
      #     # note that hash methods are still present:
      #     response.json_body.order[:key] # instead of order.key
      def json_body
        @json_body ||= Response.prepare_json_object(JSON.parse(body))
      end

      # Makes it easier to debug failed specs.
      def inspect
        "<Response(#{status})>"
      end
    end
  end
end
