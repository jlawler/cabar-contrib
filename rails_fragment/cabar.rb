Cabar::Plugin.new(:name => 'rails_fragment') do
  require 'cabar/facet/path'
  require File.join(File.dirname(__FILE__),'lib/ruby/rails_fragment.rb')
  RailsFragment::Fragments.each do |fragment|
    facet "rails/#{fragment}".to_sym,
      :env_var => "RAILS_#{fragment.to_s.upcase}_PATH".to_sym,
      :std_path => "lib/rails/#{fragment}"
  end
end

