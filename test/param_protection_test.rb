require 'helper'
require 'action_controller'

class BaseController < ActionController::Metal

  def index
    
  end
  
end

class ParamsProtectedController < BaseController
  params_protected :framework
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

class ParamsAccessiblecontroller < BaseController
  params_accessible :framework
end

class TestParamAccessible < ActiveSupport::TestCase
  
  test "should remove protected parameter" do
    request = ActionDispatch::TestRequestWithParams.new
    request.params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    controller = ParamsAccessiblecontroller.new
    controller.dispatch('index', request)

    assert_equal ({:framework => 'rails'}), controller.params
  end
end
