Cabar::Plugin.new(:name => 'rails_fragment') do
  require 'cabar/facet/path'

  facet :'rails/controllers',
      :env_var => :RAILS_CONTROLLERS_PATH,
      :std_path => 'lib/rails/controllers'

  facet :'rails/models',
      :env_var => :RAILS_MODELS_PATH,
      :std_path => 'lib/rails/models'

  facet :'rails/views',
      :env_var => :RAILS_VIEWS_PATH,
      :std_path => 'lib/rails/views'

  facet :'rails/helpers',
      :env_var => :RAILS_HELPERS_PATH,
      :std_path => 'lib/rails/helpers'

  facet :'rails/plugins',
      :env_var => :RAILS_PLUGINS_PATH,
      :std_path => 'lib/rails/plugins'
end

