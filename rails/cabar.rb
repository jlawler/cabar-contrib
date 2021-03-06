
cabar_doc= <<'DOC' 
Support for rails apps under mod_rails
There are 2 sides to the "rails_head" API.  Servers and Apps.
rails_servers must specify actions create, run, start and stop. (create and start only things implemented now)
Defaults to 'create_rails_head' and 'start_rails_head' respectively.

Apps must specify:
  port
    The HTTP port to start the server on
They can optionally specify:
  user and group 
    used to drop permissions, if run with root

  ssl_port and ssl_cert
    specify the location of the SSL cert and the port to start
    a instance of the app under SSL (Defaults to no ssl instance)

  rails_root 
    defaults to rails directory in this component

  log_dir, error_log_file and access_log_file
    specifies where the logs get put, and the error and access log
    file name respectively.  The files default to "access.log" and
    "error.log."  The directory defaults to the rails/log directory. 
DOC

cabar_rails_start = <<'DOC' 
starts the rails app using the appropriate server.
cbr rails_apps start dialer_web
DOC

Cabar::Plugin.new :documentation => cabar_doc do
  require File.join(File.dirname(__FILE__),'plugin/rails_server')
  require File.join(File.dirname(__FILE__),'plugin/rails_head')

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
      unless rails_app_f.valid_config? 
        next(puts rails_app_f.config_errors)
      end  
      
      rails_servers=get_components_by_facets('rails_server')
      next puts "No rails_server found!" unless rails_servers.size > 0

      #FIXME TODO:  Do better than defaulting to first rails_server
      rails_server_c, rails_server_f=*(rails_servers.first)

      server_opts=rails_app_f.options_for_server.dup
      server_opts.delete(:documentation)
      if server_opts and server_opts['generate_configs']
        #MOVE TO TEMP DIR?
        #rails_app -> temp_dir -> rails_server
        #fork for create_rail_from_dir action
      else
        args=hash_to_dotted(server_opts,cabar).map{|(k,v)|[k,v].join('=')}.join(',')
        #FIXME TODO:  Use the env yield crap

        fork {
          rails_server_c.facets.actions.each do |f|  
            f.execute_action! rails_server_f.create_rails_action, [cmd_args.first.dup,args, apache_template].compact, {}
          end
        }
      end
      Process.wait
      Dir.chdir rails_server_c.directory
      resolver.add_top_level_component! rails_server_c
      resolver.add_top_level_component! rails_app_c
      setup_environment!
      rails_server_c.facets.actions.each do |f|  
        f.execute_action! rails_server_f.start_rails_action, [cmd_args.first], {}
      end
    end

    class Cabar::Command
  def hash_to_dotted hsh={}, basename=nil
    hsh.inject({})do |out,(k,v)|
      next out if v.nil?
      key=k
      key="#{basename}.#{k}" if basename
      if Hash===v
         next out.merge(hash_to_dotted(v,key))
      end
      out.merge({key => v.to_s})
    end
  end

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

