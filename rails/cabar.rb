require File.join(File.dirname(__FILE__),'plugin/rails_server')
require File.join(File.dirname(__FILE__),'plugin/rails_head')
cabar_doc= <<'DOC' 
Support for rails apps under mod_rails
There are 2 sides to the "rails_head" API.  Servers and Apps.
rails_servers must specify actions create, run, start and stop. (create and start only things implemented now)
Defaults to 'create_rails_head' and 'start_rails_head' respectively.

Apps must specify:
  port

DOC

cabar_rails_start = <<'DOC' 
starts the rails app using the appropriate server.
cbr rails_apps start dialer_web
DOC

Cabar::Plugin.new :documentation => cabar_doc do
  facet :rails_server, :class => Cabar::Facet::RailsServer 
  facet :rails, :class => Cabar::Facet::RailsHead 
  cmd_group [:rails_apps] do 
    cmd [:list] do 
      print_header :rails
      puts "    rails_apps:"
      get_components_by_facets('rails').each{|x| c,f=*x
        print '    - '
        puts [c.name, c.version.to_s, c.base_directory].inspect
      }
      puts "    rails_apps:"
      get_components_by_facets('rails_server').each{|x| c,f=*x
        print '    - '
        print [c.name, c.version.to_s, c.base_directory].inspect
      }
      puts ''
    end
    cmd [:start], cabar_rails_start do 
      selection.select_dependencies = true
      selection.select_required = true
      rails_app=get_components_by_facets('rails'){|c|Regexp.new(cmd_args.first)===c.name}
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
      def get_components_by_facets key
        result = [ ]
        selection.to_a.each do | c |
          next if block_given?  && !yield(c)
          c.facets.each do | f |
            if f.key ==  key
              result <<  [c,f]
            end
          end
        end
        result
      end
    end
  end
end

