require File.expand_path('test_helper', File.dirname(__FILE__))
require 'action_controller'

class BaseController < ActionController::Base
  def index
    render :nothing => true
  end
end

class ParamsProtectedController < BaseController
  protected_params :framework
end

class TestParamProtection < ActiveSupport::TestCase
  test "should remove protected parameter" do
    request = ActionDispatch::TestRequestWithParams.new
    request.params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    controller = ParamsProtectedController.new
    controller.dispatch('index', request)

    assert_equal ({:user => 'slawosz',:lang => 'ruby'}), controller.params
  end
end

class ParamsAccessibleController < BaseController
  allowed_params :framework
end

class TestParamAccessible < ActiveSupport::TestCase
  test "should preserve allowed parameter" do
    request = ActionDispatch::TestRequestWithParams.new
    request.params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    controller = ParamsAccessibleController.new
    controller.dispatch('index', request)

    assert_equal ({:framework => 'rails'}), controller.params
  end
end

class FooController < BaseController
  allowed_params :framework
end

class BarController < FooController
  allowed_params :user
end

class TestParamsAccessibleInheritance < ActiveSupport::TestCase
  test "remember accessible parameters from superclass" do
    request = ActionDispatch::TestRequestWithParams.new
    request.params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    controller = BarController.new
    controller.dispatch('index', request)

    assert_equal ({:framework => 'rails', :user => 'slawosz'}), controller.params
  end
end

class MultipleAllowedParamsDefinitionsController < BarController
  allowed_params :framework
  allowed_params :user
end

class TestMultipleAllowedParamsDefinitions < ActiveSupport::TestCase
  test "use all declared parameters" do
    request = ActionDispatch::TestRequestWithParams.new
    request.params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    controller = MultipleAllowedParamsDefinitionsController.new
    controller.dispatch('index', request)

    assert_equal ({:framework => 'rails', :user => 'slawosz'}), controller.params
  end
end
