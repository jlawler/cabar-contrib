
module Cabar
  class Facet
    class RailsServer < self
      attr_accessor :create_rails_action
      attr_accessor :start_rails_action
      attr_accessor :derby_options
      COMPONENT_ASSOCATIONS = [ 'provides'.freeze].freeze 
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
  end
end

