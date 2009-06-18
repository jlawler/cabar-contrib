module Cabar
  class Facet
    unless defined?(RailsServer)
    class RailsServer < self
      attr_accessor :create_rails_action
      attr_accessor :start_rails_action
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze unless defined?(COMPONENT_ASSOCATIONS)
      def name
        'rails_server'
      end
      def component_associations
        COMPONENT_ASSOCATIONS
      end
      def create_rails_action
        @create_rails_action || 'create_rails_head'
      end 
      def start_rails_action
        @start_rails_action || 'start_rails_head'
      end 
      def is_composable?
        false
      end
    end
    class RailsHead < self

      attr_accessor :group
      attr_accessor :user
      attr_accessor :port
      attr_accessor :ssl_port
      attr_accessor :ssl_cert
      attr_accessor :rails_root
      attr_accessor :apache_template
      attr_accessor :log_dir
      attr_accessor :error_log_file
      attr_accessor :access_log_file
      attr_accessor :tmp
      RAILS_FIELDS=[:tmp, :access_log_file, :error_log_file, :log_dir, :rails_root, :ssl_cert, :ssl_port, :port, :user, :group] unless defined?(RAILS_FIELDS)
      def access_log_file
        File.join(log_dir,@access_log_file || "access.log")
      end
      def error_log_file 
        File.join(log_dir,@access_log_file || "error.log")
      end
      def log_dir
        @log_dir || File.join(rails_root,'log')
      end
      def rails_root
        File.join(rails_root,"public")
      end
      def rails_root
        @rails_root ||= begin
$stderr.puts self.component
          x=File.expand_path(File.join(self.component.base_directory,'rails'))
          x if File.exist? x
        end
      end
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze unless defined? COMPONENT_ASSOCATIONS
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
Support for rails apps under mod_rails
There are 2 sides to the "rails_head" API.  Servers and Apps.
rails_servers must specify actions create, run, start and stop. (create and start only things implemented now)
Defaults to 'create_rails_head' and 'start_rails_head' respectively.

Apps must specify:
  port

DOC
  facet :rails_server, :class => Cabar::Facet::RailsServer 
  facet :rails, :class => Cabar::Facet::RailsHead 
  cmd_group [:rails_apps] do 
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
    cmd [:start], <<'DOC' do 
starts the rails app using the appropriate server.
cbr rails_apps start dialer_web
DOC
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
      def get_mod_rails_comp
        selection.to_a.each do | c |
          return c if c.name=~/rails/
        end
      end
      def get_rails_servers match=nil
        result = [ ]
        selection.to_a.each do | c |
          next if match && ! (match === c.name)
          c.facets.each do | f |
            if f.key == 'rails_server' 
              result <<  [c,f]
            end
          end
        end
        result
      end

      def get_rails_apps match=nil
        result = [ ]
        selection.to_a.each do | c |
          next if match && ! (match === c.name)
          c.facets.each do | f |
            if f.key == 'rails' 
              result <<  [c,f]
            end
          end
        end
        result
      end
    end
  end
end

