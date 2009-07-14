
# Interface to rails_fragment rails/* Facets.
module RailsFragment
  # Fragments=[ :controllers, :models, :views, :helpers, :plugins ]
  Fragments=[ :controllers, :models, :plugins ].freeze
  FragmentConfig={}
  Fragments.each do|frag|
    temp=ENV["RAILS_#{frag.to_s.upcase}_PATH"]||''
    FragmentConfig[frag] = temp.split(':').compact.freeze 
  end
  FragmentConfig.freeze

  def self.configure_rails config
    FragmentConfig[:plugins].each{|p| config.plugin_paths << p } 
    FragmentConfig[:models].each{|p| config.load_paths << p } 
    FragmentConfig[:controllers].each do|p| 
      config.controller_paths << p
      config.load_paths << p 
    end
  end
  def self.path name = nil
    @@path ||=
      begin
        h = { }
        Fragments.each do | n |
      	  n_v = n.to_s.upcase
      	  h[n] = (ENV["RAILS_#{n_v}_PATH"] || '').split(':')
      	end
      	h
      end
    name ? @@path[name.to_sym] : @path
  end
end

