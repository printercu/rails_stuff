require 'active_support/core_ext/array/wrap'
module RailsStuff
  module Helpers
    # Provides helper for SimpleForm.
    module ResourceForm
      # Generates `resource_form` helper to display form with basic arguments,
      # elements, errors and options. Generated method can work without arguments
      # in most of cases: it takes object from `resource` method.
      #
      # Use `namespace` to add additional path parts to form action:
      #
      #     # this one will use [:site, resource]
      #     resource_form_for :site
      #
      # #### Options
      #
      # - `back_url` - default back url. Can be string with code, or hash for `url_for`.
      # - `resource_method` - method to take resource from.
      # - `method` - name of generated method.
      #
      def resource_form_for(namespace = nil, **options)
        default_back_url =
          case options[:back_url]
          when Hash then "url_for(#{options[:back_url]})"
          when String then options[:back_url]
          else 'url_for(object)'
          end
        resource_method = options.fetch(:resource_method, :resource)
        method_name = options.fetch(:method, :resource_form)
        object_arg = (Array.wrap(namespace).map(&:inspect) + [resource_method]).join(', ')

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method_name}(object = [#{object_arg}], **options)
            back_url = options.delete(:back_url) || #{default_back_url}
            simple_form_for object, options do |f|
              html = ActiveSupport::SafeBuffer.new
              msg = f.object.errors[:base].first
              html << content_tag(:div, msg, class: 'alert alert-danger') if msg
              html << capture { yield(f) }
              html << content_tag(:div, class: 'form-group') do
                inputs = f.button(:submit, class: 'btn-primary')
                inputs << ' '
                inputs << link_to(translate_action(:cancel), back_url, class: :btn)
              end
            end
          end
        RUBY
      end
    end
  end
end
