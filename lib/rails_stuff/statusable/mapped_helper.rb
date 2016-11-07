module RailsStuff
  module Statusable
    # Helper to hold
    class MappedHelper < Helper
      attr_reader :mapping, :inverse_mapping, :indifferent_mapping

      def initialize(*)
        super
        @mapping = @list
        @indifferent_mapping = mapping.with_indifferent_access
        @list = mapping.keys.freeze
        @inverse_mapping = mapping.invert.freeze
      end

      def select_options(original: false, only: nil, except: nil)
        return super(only: only, except: except) unless original
        only ||= mapping_values
        only -= except if except
        only.map { |x| [translate(inverse_mapping.fetch(x)), x] }
      end

      def mapping_values
        @mapping_values ||= mapping.values
      end

      def map(val)
        map_with(indifferent_mapping, val)
      end

      def unmap(val)
        map_with(inverse_mapping, val)
      end

      protected

      # Maps single value or array with given map.
      def map_with(map, val)
        if val.is_a?(Array)
          val.map { |x| map.fetch(x, x) }
        else
          map.fetch(val, val)
        end
      end
    end
  end
end
