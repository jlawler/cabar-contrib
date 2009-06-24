module Cabar
  class Facet
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

