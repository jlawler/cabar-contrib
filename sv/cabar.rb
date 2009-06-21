plugin=File.join(File.dirname(__FILE__),'plugin/runsv.rb')
require plugin 
module Cabar
  class Facet
    unless defined?(SvService)
    SvReservedNames=[:runsv, :autostart, :log, :finish, :nolink, :user, :group, :fix_permissions,:finish_timeout].freeze
    class SvServiceGroup < self
      attr_accessor *SvReservedNames
      alias :runsv_dir :runsv
      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end
      def config_self
        conf=vars.reject{|k,v|(Hash===v)}
        SvReservedNames.each{|n| instance_variable_set('@'+n.to_s, conf.delete(n.to_s))}
        if conf.keys.size > 0
          puts "Unknown config options #{conf.keys.join(', ')}"
          raise "invalid config, jackass"
        end
      end
      def compose_facet! facet
        config_self
        self
      end

      # Creates individual EnvVar facets for each
      # key/value pair in the option Hash.
      def attach_component! c
        config_self
        
        vars.each do | n, v |
          next unless Hash===v
          c.create_facet(:sv_service, v.merge({:service_name => n, :service_group => self}))
        end
      end
    end # class

    class SvService < self
      def self.inherit_attribute *args
        args.each do |func|
          define_method(func.to_s + '=', lambda {|new_val|
            instance_variable_set('@'+func.to_s,new_val)
          })  
          define_method(func, lambda{
            instance_variable_get('@'+func.to_s) || self.service_group.send(func)
          })  
        end
      end
      inherit_attribute *SvReservedNames
      attr_accessor :script, :service_name, :dir, :action, :service_group, :bin
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze unless defined?(COMPONENT_ASSOCATIONS)
      def initialize *args
        self.fix_permissions=true
        self.finish_timeout=true
        super
      end
      def runsv_dir
        @runsv || self.service_group.runsv_dir || "screwed"
      end 
      def finish! exit_status=nil
        STDERR.puts "timeout finish-hook"  if self.should_finish?
      end
      def should_finish?
        @finish_timeout
      end
      def fix_permissions?
        (self.user or self.group) and self.fix_permissions
      end
      def execute!
        self.fix_permissions! if fix_permissions?
        return STDERR.puts "FAKE EXECUTING SCRIPT #{script}" if script
        return STDERR.puts "FAKE EXECUTING SCRIPT #{action}" if action
        return STDERR.puts "FAKE EXECUTING SCRIPT #{bin}" if bin
      end
      def fix_permissions!
        STDERR.puts "fixing permissions on #{self.service_dir} to #{self.user.inspect}:#{self.group.inspect}"
      end
      def tell_service cmd
        #check for permissions
        puts "#{cmd}ing #{self.service_name}"
      end
      def service_dir
        [@dir, (self.component.base_directory and File.join(self.component.base_directory,'svc'))].find {|f| f and File.exists?(f)}
      end
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
   def get_sv_services match=nil
      result ={}
      selection.to_a.each do | c |
        c.facets.each do | f |
          if f.key == 'sv_service' && (match.nil? or match===f.service_name)
            result[c.name]=[c,f]
          end
        end
      end
      result
    end
    def get_one_service match=nil
      services=get_sv_services(match)
      unless services.values.first
        return puts "unknown service #{cmd_args.first}"
      end
      services.values.first.last
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
  facet :sv, :class => Cabar::Facet::SvServiceGroup 
  facet :sv_service, :class => Cabar::Facet::SvService 
  cmd_group [:sv] do
    cmd [:create] do
      puts "not implemented" 
    end 
    cmd [:remove] do 
      puts "not implemented" 
    end 
    cmd [:__run__] do
        selection.select_dependencies = true
        selection.select_required = true
        service=nil
        
        next unless service=get_one_service(Regexp.new('^' + cmd_args.first + '$'))
        puts service.runsv_dir
        service.execute!
        puts "starting #{cmd_args.first}"
    end 
    cmd [:__finish__] do
        selection.select_dependencies = true
        selection.select_required = true
        service=nil
        next unless service=get_one_service(Regexp.new('^' + cmd_args.first + '$'))
        service.finish!
        puts "finishing #{cmd_args.first}"
    end 
    Runsv::COMMANDS.each do|command|
      cmd [command] do 
        service=nil
        return unless service=get_one_service(Regexp.new('^' + cmd_args.first + '$'))
        service.tell_service command
      end
    end
    cmd [:list], "" do 
      selection.select_dependencies = true
      selection.select_required = true
      registered_services=get_sv_services
      puts registered_services.values.map{|a|a[1].service_name}.join("\n")
      #puts services.values.map{|a|a[0].base_directory}.join("\n")
      #puts services.values.map{|v|v.inspect.gsub(/^[\s-]$/,'')}.join("\n")
    end
  end
end

