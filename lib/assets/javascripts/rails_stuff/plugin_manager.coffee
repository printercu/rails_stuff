# Provides simple way to create jQuery plugins. Create class and PluginManager
# will create jQuery function for it. It'll create instance of class for each
# jQuery element and prevent calling constructor twice.
#
#     PluginManager.add 'myPlugin', class
#       constructor: (@$element, @options) ->
#          # ...
#
#       customAction: (options)->
#          # ...
#
#       # Add initializers
#       $ -> $('[data-my-plugin]').myPlugin()
#       # or
#       $(document).on 'click', '[data-my-plugin]', (e) ->
#         $(@).myPlugin('customAction', event: e)
#
#     # Or use it manually
#     $('.selector').myPlugin().myPlugin('customAction')
class window.PluginManager
  @plugins = {}

  # Takes class and creates jQuery's plugin function for it.
  # This function simply creates class instance for each element
  # and prevents creating multiple instances on single element.
  #
  # Name is set explicitly to avoid errors when using uglifier.
  @add: (pluginName, klass) ->
    data_index = "#{pluginName}.instance"
    @plugins[pluginName] = klass
    jQuery.fn[pluginName] = (action, options) ->
      if typeof action is 'object'
        options = action
        action = null
      @each ->
        $this = jQuery @
        unless instance = $this.data data_index
          instance = new klass $this, options
          $this.data data_index, instance
        instance[action](options) if action
