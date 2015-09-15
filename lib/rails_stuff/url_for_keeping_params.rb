ActionDispatch::Routing::UrlFor.class_eval do
  # Safe way to generate url keeping params from request.
  #
  # It requires `request` to be present. Please don't use it in mailers
  # or in other places where it's not supposed to.
  def url_for_keeping_params(params)
    url_for params: request.query_parameters.merge(params)
  end
end
