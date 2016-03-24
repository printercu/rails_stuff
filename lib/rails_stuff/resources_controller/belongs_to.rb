module RailsStuff
  module ResourcesController
    module BelongsTo
      class << self
        # Builds lambda to use as `#source_relation`.
        def source_relation(subject, collection, optional: false, **)
          check_subject = :"#{subject}?"
          lambda do
            if optional && !send(check_subject)
              super()
            else
              send(subject).public_send(collection)
            end
          end
        end

        # Builds lambda to use as `#index_url`
        def index_url(subject, *, field: nil, param: nil)
          field ||= :"#{subject}_id"
          param ||= field
          -> { url_for action: :index, param => resource.public_send(field) }
        end
      end

      # Defines resource helper and source relation
      def resource_belongs_to(subject, resource_helper: true, urls: true, **options)
        resource_helper(subject) if resource_helper
        collection = options[:collection] || resource_class.model_name.plural
        source_relation_proc = BelongsTo.source_relation(subject, collection, options)
        protected define_method(:source_relation, &source_relation_proc)
        protected define_method(:index_url, &BelongsTo.index_url(subject, urls)) if urls
      end
    end
  end
end
