
# Interface to rails_fragment rails/* Facets.
module RailsFragment
  EXTRA_RAILS_MODEL_PATHS=[*(ENV['RAILS_MODELS_PATHS'].split(':'))].compact
  EXTRA_RAILS_CONTROLLER_PATHS=[*(ENV['RAILS_CONTROLLERS_PATHS'].split(':'))].compact

  def self.configure_rails config
    if defined? ::AUTOLOAD_PATHS
      ::AUTOLOAD_PATHS << EXTRA_RAILS_MODEL_PATHS
      ::AUTOLOAD_PATHS << EXTRA_RAILS_CONTROLLER_PATHS
    else
      STDERR.puts "WARNING:  AUTOLOAD_PATHS WASN'T DEFINED!"
    end
    config.controller_paths << EXTRA_RAILS_CONTROLLER_PATHS
  end
  def self.path name = nil
    @@path ||=
      begin
        h = { }
        [ :controllers, :models, :views, :helpers, :plugins ].each do | n |
      	  n_v = n.to_s.upcase
      	  h[n] = (ENV["RAILS_#{n_v}_PATH"] || '').split(':')
      	end
      	h
      end
    name ? @@path[name.to_sym] : @path
  end
end

