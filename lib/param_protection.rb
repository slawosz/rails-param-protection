require 'active_support/concern'
require 'action_controller'
require 'sanitizer'

module ActionController
  module ParamProtectionApi
    extend ActiveSupport::Concern

    included do
      class_attribute :_protected_parameters
      class_attribute :_accessible_parameters
    end

    module ClassMethods

      def params_protected(params)
        self._protected_parameters = params
        include ParamProtection
      end

      def params_accessible(params)
        self._accessible_parameters = params
        include ParamProtection
      end
  
    end    
  end

  module ParamProtection
    
    def dispatch(action, request)
      protect_parameters(request)
      super(action, request)
    end

    private

    def protect_parameters(request)
      request.parameters.extend(Sanitizer)
      request.parameters.sanitize(self.class._protected_parameters) if self.class._protected_parameters.present?
      request.parameters.sanitize_except(self.class._accessible_parameters) if self.class._accessible_parameters.present?
    end
    
  end

  class Metal
    include ParamProtectionApi
  end
  
end
