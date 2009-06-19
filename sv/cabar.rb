module Cabar
  class Facet
    unless defined?(SvService)
    class SvService < self
      attr_accessor :script, :autostart, :log, :finish
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
  facet :sv, :class => Cabar::Facet::SvService 
  cmd_group [:sv] do 
    cmd [:list], <<'DOC' do 

DOC

      print_header :rails
      puts "    rails_apps:"
      get_rails_apps.each{|x| c,f=*x
        print '    - '
        puts [c.name, c.version.to_s, c.base_directory].inspect
      }
      puts "    rails_apps:"
      get_rails_servers.each{|x| c,f=*x
        print '    - '
        print [c.name, c.version.to_s, c.base_directory].inspect
      }

    end
    cmd [:start], "starts the rails app using the appropriate server.\ncbr rails_apps start dialer_web\n"
      selection.select_dependencies = true
      selection.select_required = true
      rails_app=get_rails_apps Regexp.new(cmd_args.first)
      rails_app_c, rails_app_f=*(rails_app.first)
      rails_servers=selection.to_a.map{|c|c.facets.inject(nil){|ret,f| ret ||( f.name=='rails_server' ? [c,f] : nil )}}.compact
      unless rails_servers.size > 0
        puts "No rails_server found!" 
        next
      end
      #FIXME TODO:  Do better than defaulting to first rails_server
      rails_server_c, rails_server_f=*(rails_servers.first)
      args=Cabar::Facet::RailsHead::RAILS_FIELDS.map{|i| "#{i}=#{rails_app_f.send(i)}" if rails_app_f.send(i) }.compact.join(',')
      fork {
      rails_server_c.facets.each do |f|  
        if f.key=='action'
          f.execute_action! rails_server_f.create_rails_action, [cmd_args.first.dup,args, apache_template].compact, {}
        end
      end
      }
      Process.wait
      Dir.chdir rails_server_c.directory
      resolver.add_top_level_component! rails_server_c
      resolver.add_top_level_component! rails_app_c
      setup_environment!
      rails_server_c.facets.each do |f|  
        if f.key=='action'
          f.execute_action! rails_server_f.start_rails_action, [cmd_args.first], {}
        end
      end
    end

    class Cabar::Command
      module Sv
        def get_sv_services match=nil
          result = [ ]
          selection.to_a.each do | c |
            next if match && ! (match === c.name)
            c.facets.each do | f |
              if f.key == 'sv' 
                result <<  [c,f]
              end
            end
          end
          result
        end
      end
    end

