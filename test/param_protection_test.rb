require File.expand_path('test_helper', File.dirname(__FILE__))

class TestParamProtection < ActionController::TestCase

  class BaseController < ActionController::Base
    class << self
      attr_accessor :last_parameters
    end

    def index
      self.class.last_parameters = request.params.except(:controller, :action)
      render :nothing => true
    end
  end

  class ParamsProtectedController < BaseController
    params_protected :framework
  end

  test "should remove protected parameter" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = _process(ParamsProtectedController, params)

    assert_equal ({:user => 'slawosz',:lang => 'ruby'}), result
  end

  class ParamsAccessibleController < BaseController
    params_accessible :framework
  end

  test "should preserve allowed parameter" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = _process(ParamsAccessibleController, params)

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

    result = _process(BarAllowedController, params)

    assert_equal ({:framework => 'rails', :user => 'slawosz'}), result
  end

  class MultipleAllowedParamsDefinitionsController < BaseController
    params_accessible :framework
    params_accessible :user
  end

  test "use parameters from each declaration" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = _process(MultipleAllowedParamsDefinitionsController, params)

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

    result = _process(BarProtectedController, params)

    assert_equal ({:lang => 'ruby'}), result
  end

  class MultipleProtectedParamsDefinitionsController < BaseController
    params_protected :framework
    params_protected :user
  end

  test "protect parameters from each declaration" do
    params = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    result = _process(MultipleProtectedParamsDefinitionsController, params)

    assert_equal ({:lang => 'ruby'}), result
  end

  class TwoAllowedParamsController < BaseController
    params_accessible ({:user => {:type => {:admin => [:login, :email]}}}), :url
  end

  test "should allow two params" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = _process(TwoAllowedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com'}}}, :url => 'slawosz.github.com'}), result
  end

  class TwoProtectedParamsController < BaseController
    params_protected ({:user => {:type => {:admin => [:login, :email]}}}), :url
  end

  test "should protect two params" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = _process(TwoProtectedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:language => 'ruby'}), result
  end

  class OneComplexAllowedParamsController < BaseController
    params_accessible :user => {:type => {:admin => [:login, :email]}}
  end

  test "should allow one param using complex definition" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = _process(OneComplexAllowedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com'}}}}), result
  end

  class OneComplexProtectedParamsController < BaseController
    params_protected :user => {:type => {:admin => [:login, :email]}}
  end

  test "should protect one param using complex definition" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    result = _process(OneComplexProtectedParamsController, params)

    assert_equal ({:user => {:type => {:admin => {:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}), result
  end

  class WrongParamsFilteringDefinition < BaseController
    params_protected :foo
    params_accessible :bar
  end

  test "should raise error when both filtering exists in controller" do
    params = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}

    assert_raise RailsParamProtection::ParamsFilteringDefinitionMismatch do
      _process(WrongParamsFilteringDefinition, params)
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

    assert_raise RailsParamProtection::ParamsFilteringDefinitionMismatch do
      _process(SubWrongParamsFilteringDefinition, params)
    end

  end

  test "should work without params" do
    result = _process(OneComplexProtectedParamsController, nil)
    assert result.blank?

    result = _process(OneComplexAllowedParamsController, nil)
    assert result.blank?

    result = _process(OneComplexProtectedParamsController, {})
    assert result.blank?

    result = _process(OneComplexAllowedParamsController, {})
    assert result.blank?
  end

  private
  def _process(controller, params)
    @controller = controller.is_a?(Class) ? controller.new : controller

    get :index, params
    @controller.class.last_parameters.symbolize_keys
  end
end
