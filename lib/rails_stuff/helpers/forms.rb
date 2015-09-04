module RailsStuff
  module Helpers
    module Forms
      # Returns hidden field tags for requested fields when they are present in params.
      # Usually used to bypass params in GET-forms.
      def hidden_params_fields(*fields)
        inputs = fields.flat_map do |field|
          next unless params.key?(field)
          val = params[field]
          if val.is_a?(Array)
            name = "#{field}[]"
            val.map { |str| [name, str] }
          else
            [[field, val]]
          end
        end
        safe_join inputs.map { |(name, val)| hidden_field_tag name, val if name }
      end
    end
  end
end
