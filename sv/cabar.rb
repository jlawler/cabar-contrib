module Cabar
  class Facet
    unless defined?(SvService)
    class SvServiceGroup < self
      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end

      def compose_facet! facet
        self
      end

      # Creates individual EnvVar facets for each
      # key/value pair in the option Hash.
      def attach_component! c
        vars.each do | n, v |
          c.create_facet(:sv_service, v.merge({:service_name => n}))
        end
      end
    end # class

    class SvService < self
      attr_accessor :script, :autostart, :log, :finish, :service_name
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze unless defined?(COMPONENT_ASSOCATIONS)
      def name
        'sv_service'
      end
      def component_associations
        COMPONENT_ASSOCATIONS
      end
      def is_composable?
        false
      end
    end
    end
  end
end
class Cabar::Command
 #  module Sv
   def get_sv_services match=nil
      result ={}
      selection.to_a.each do | c |
        next if match && ! (match === c.name)
        c.facets.each do | f |
          if f.key == 'sv_service' 
            result[c.name]=[c,f]
          end
        end
      end
      result
    end
#  end
end

Cabar::Plugin.new :documentation => <<'DOC' do 
Support for easy creation and manipulation of sv/runit services under cabar
Componets can just specify the script to run, or specify options.

Example 1: 
sv:
  service_name: action

Example 2:
sv:
  service_name: 
    action: action_name
    finish: finish_script
    log: log stuff
    autostart: true
DOC
  facet :sv, :class => Cabar::Facet::SvServiceGroup 
  facet :sv_service, :class => Cabar::Facet::SvService 
  cmd_group [:sv] do 
    cmd [:list], "" do 
      selection.select_dependencies = true
      selection.select_required = true
      
      services=get_sv_services
      puts services.values.map{|a|a[1].service_name}.join("\n")
      #puts services.values.map{|v|v.inspect.gsub(/^[\s-]$/,'')}.join("\n")

    end
    cmd [:start], "starts the rails app using the appropriate server.\ncbr rails_apps start dialer_web\n" do 
      selection.select_dependencies = true
      selection.select_required = true
    end
  end
end

