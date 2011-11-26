require 'active_support/concern'
require 'action_controller'
require 'sanitizer'
require 'active_support/core_ext/hash/deep_dup'
require 'active_support/core_ext/hash/deep_merge'

module RailsParamProtection
  class ParamsFilteringDefinitionMismatch < Exception; end

  module Api
    extend ActiveSupport::Concern

    included do
      class_attribute :_protected_parameters
      class_attribute :_allowed_parameters
    end

    module ClassMethods

      def params_protected(*params)
        self._protected_parameters ||= []
        params.each do |param|
          self._protected_parameters << param
        end
      end

      def params_accessible(*params)
        self._allowed_parameters ||= []
        params.each do |param|
          self._allowed_parameters << param
        end
      end

    end

    module InstanceMethods
      # should be process_action like in actionpack/lib/action_controller/metal/params_wrapper.rb
      def process_action(*args)
        protect_parameters(request)
        super
      end

      private
      def protect_parameters(request)
        if self.class._allowed_parameters.present? && self.class._protected_parameters.present?
          raise ParamsFilteringDefinitionMismatch
        end
        request.parameters.class.class_eval do
          include RailsParamProtection::Sanitizer
        end
        process_allowed_parameters(request) if self.class._allowed_parameters.present?
        process_protected_parameters(request) if self.class._protected_parameters.present?
      end

      def process_allowed_parameters(request)
        allowed_parameters = {}
        self.class._allowed_parameters.each do |param|
          allowed_parameters.deep_merge!(request.parameters.deep_dup.sanitize_except!(param))
        end
        request.parameters.replace allowed_parameters
        request.request_parameters.replace allowed_parameters
      end

      def process_protected_parameters(request)
        self.class._protected_parameters.each do |param|
          request.parameters.sanitize!(param)
          request.request_parameters.sanitize!(param)
        end
      end
    end
  end
end

module ActionController

  class Base
    include RailsParamProtection::Api
  end

end
