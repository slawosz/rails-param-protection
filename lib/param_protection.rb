require 'active_support/concern'
require 'action_controller'
require 'sanitizer'
require 'active_support/core_ext/hash/deep_dup'
require 'active_support/core_ext/hash/deep_merge'

module RailsParamsProtection
  module Api
    extend ActiveSupport::Concern

    included do
      class_attribute :_protected_parameters
      class_attribute :_allowed_parameters
    end

    module ClassMethods

      def protected_params(params)
        self._protected_parameters ||= []
        self._protected_parameters << params
      end

      def allowed_params(params)
        self._allowed_parameters ||= []
        self._allowed_parameters << params
      end

    end

    module InstanceMethods
      def dispatch(action, request)
        protect_parameters(request)
        super(action, request)
      end

      private
      def protect_parameters(request)
        request.parameters.class.class_eval do
          include RailsParamsProtection::Sanitizer
        end
        process_allowed_parameters(request) if self.class._allowed_parameters.present?
        process_protected_parameters(request) if self.class._protected_parameters.present?
      end

      def process_allowed_parameters(request)
        allowed_parameters = {}
        self.class._allowed_parameters.each do |param|
          allowed_parameters.deep_merge!(request.parameters.deep_dup.sanitize_except!(param))
        end
        request.params = allowed_parameters
      end

      def process_protected_parameters(request)
        protected_parameters = {}
        self.class._protected_parameters.each do |param|
          protected_parameters.deep_merge!(request.parameters.deep_dup.sanitize!(param))
        end
        request.params = protected_parameters
      end
    end
  end
end

module ActionController

  class Base
    include RailsParamsProtection::Api
  end

end
