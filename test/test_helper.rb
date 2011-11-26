require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rails-param-protection'
require 'test_request_with_params'
require 'ruby-debug'

module SetupOnce
  extend ActiveSupport::Concern

  included do
    cattr_accessor :setup_once_block
    self.setup_once_block = nil

    setup :run_setup_once
  end

  module ClassMethods
    def setup_once(&block)
      self.setup_once_block = block
    end
  end

  private
    def run_setup_once
      if self.setup_once_block
        self.setup_once_block.call
        self.setup_once_block = nil
      end
    end
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

module ActiveSupport
  class TestCase
    include SetupOnce
    # Hold off drawing routes until all the possible controller classes
    # have been loaded.
    setup_once do
      SharedTestRoutes.draw do
        match ':controller(/:action)'
      end
    end
  end
end

module ActionController
  class Base
    include ActionController::Testing
    # This stub emulates the Railtie including the URL helpers from a Rails application
    include SharedTestRoutes.url_helpers

    def self.test_routes(&block)
      routes = ActionDispatch::Routing::RouteSet.new
      routes.draw(&block)
      include routes.url_helpers
    end
  end

  class TestCase
    include ActionDispatch::TestProcess

    setup do
      @routes = SharedTestRoutes
    end
  end
end


