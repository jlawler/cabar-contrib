module Cabar
  class Facet
    class RailsHead < self
      attr_accessor :group
      attr_accessor :user
      attr_accessor :port
      attr_accessor :ssl_port
      attr_accessor :ssl_cert
      attr_accessor :rails_root
      attr_accessor :log_dir
      attr_accessor :error_log_file
      attr_accessor :access_log_file
      attr_accessor :tmp
      attr_accessor :server

      RAILS_FIELDS=[:tmp, :access_log_file, :error_log_file, :log_dir, :rails_root, :ssl_cert, :ssl_port, :port, :user, :group]
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze 
      def options_for_server
        a=RAILS_FIELDS.inject(_options.dup||{}) do |opts,field|
          opts.merge({field =>self.send(field)})
        end
        a
      end
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
          x=File.expand_path(File.join(self.component.base_directory,'rails'))
          x if File.exist? x
        end
      end
      def component_associations
        COMPONENT_ASSOCATIONS
      end
      def valid_config?
        config_errors.size==0
      end
      def config_errors
        errors=[]
        unless File.exists? rails_root
          errors << "invalid rails_root #{rails_root}"
        end 
        if log_dir and not File.exists?(log_dir)
          errors << "invalid log directory specified #{rails_root}"
        end
        if ssl_cert.nil? ^ ssl_port.nil?
          if ssl_cert
            errors << "ssl_cert specified, but no ssl_port defined"
          else
            errors << "ssl_port specified, but no ssl_cert defined"
          end 
        end
        if ssl_cert and not File.exists?(ssl_cert)
            errors << "can't find file #{ssl_cert}"
        end
        errors
      end
      def is_composable?
        false
      end
    end
  end
end

