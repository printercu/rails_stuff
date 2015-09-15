ActionController::Parameters.class_eval do
  # Permits and then checks all fields for presence.
  def require_permitted(*fields)
    permit(*fields).tap { |permitted| fields.each { |f| permitted.require(f) } }
  end
end
