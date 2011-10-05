require File.expand_path('test_helper', File.dirname(__FILE__))
require 'action_controller'

class TestParamProtection < ActiveSupport::TestCase

  class BaseController < ActionController::Base
    def index
      render :nothing => true
    end
  end

  class ParamsProtectedController < BaseController
    params_protected :framework
  end

  test "should remove protected parameter" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(ParamsProtectedController, params)

    assert_equal ({:user => 'slawosz',:lang => 'ruby'}), result
  end

  class ParamsAccessibleController < BaseController
    params_accessible :framework
  end

  test "should preserve allowed parameter" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(ParamsAccessibleController, params)

    assert_equal ({:framework => 'rails'}), result
  end

  class FooAllowedController < BaseController
    params_accessible :framework
  end

  class BarAllowedController < FooAllowedController
    params_accessible :user
  end

  test "remember accessible parameters from superclass" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(BarAllowedController, params)

    assert_equal ({:framework => 'rails', :user => 'slawosz'}), result
  end

  class MultipleAllowedParamsDefinitionsController < BaseController
    params_accessible :framework
    params_accessible :user
  end

  test "use parameters from each declaration" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(MultipleAllowedParamsDefinitionsController, params)

    assert_equal ({:framework => 'rails', :user => 'slawosz'}), result
  end

  class FooProtectedController < BaseController
    params_protected :framework
  end

  class BarProtectedController < FooProtectedController
    params_protected :user
  end

  test "remember protected parameters from superclass" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(BarProtectedController, params)

    assert_equal ({:lang => 'ruby'}), result
  end

  class MultipleProtectedParamsDefinitionsController < BaseController
    params_protected :framework
    params_protected :user
  end

  test "protect parameters from each declaration" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = process(MultipleProtectedParamsDefinitionsController, params)

    assert_equal ({:lang => 'ruby'}), result
  end

  class TwoAllowedParamsController < BaseController
    params_accessible ({:user => {:type => {:admin => [:login, :email]}}}), :url
  end

  test "should allow two params" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = process(TwoAllowedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com'}}}, :url => 'slawosz.github.com'}), result
  end

  class TwoProtectedParamsController < BaseController
    params_protected ({:user => {:type => {:admin => [:login, :email]}}}), :url
  end

  test "should protect two params" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = process(TwoProtectedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:language => 'ruby'}), result
  end

  class OneComplexAllowedParamsController < BaseController
    params_accessible :user => {:type => {:admin => [:login, :email]}}
  end

  test "should allow one param using complex definition" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = process(OneComplexAllowedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com'}}}}), result
  end

  class OneComplexProtectedParamsController < BaseController
    params_protected :user => {:type => {:admin => [:login, :email]}}
  end

  test "should protect one param using complex definition" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = process(OneComplexProtectedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}), result
  end

  class WrongParamsFilteringDefinition < BaseController
    params_protected :foo
    params_accessible :bar
  end

  test "should raise error when both filtering exists in controller" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    assert_raise RailsParamsProtection::ParamsFilteringDefinitionMismatch do
      process(WrongParamsFilteringDefinition, params)
    end

  end

  class BaseWrongParamsFilteringDefinition < BaseController
    params_protected :foo
  end

  class SubWrongParamsFilteringDefinition < BaseWrongParamsFilteringDefinition
    params_accessible :bar
  end

  test "should raise error when both filtering exists in controller inheritance hierarchy" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    assert_raise RailsParamsProtection::ParamsFilteringDefinitionMismatch do
      process(SubWrongParamsFilteringDefinition, params)
    end

  end

  private
  def process(controller, params)
    request = ActionDispatch::TestRequestWithParams.new
    request.params = params
    controller_instance = controller.new
    dispatched = controller_instance.dispatch('index', request)
    controller_instance.params
  end
end
