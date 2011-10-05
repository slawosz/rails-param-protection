require File.expand_path('test_helper', File.dirname(__FILE__))

class Hash
  include RailsParamsProtection::Sanitizer
end

class SanitizerTest < ActiveSupport::TestCase

  setup do
    @hash = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}
  end

  test 'should remove one key' do
    @hash.sanitize!(:user)

    expected = {:url => 'slawosz.github.com',:language => 'ruby'}
    assert_equal expected, @hash

    hash = {:user => 'slawosz',:framework => 'rails',:lang => 'ruby'}

    hash.sanitize!(:user)

    expected = {:framework => 'rails',:lang => 'ruby'}
    assert_equal expected, hash
  end

  test 'should preserve one key' do
    @hash.sanitize_except!(:user)
    expected = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'}}
    assert_equal expected, @hash
  end

  test 'should remove two keys' do
    @hash.sanitize!(:user,:url)

    expected = {:language => 'ruby'}
    assert_equal expected, @hash
  end

  test 'should preserve two keys' do
    @hash.sanitize_except!(:user, :url)
    expected = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com'}
    assert_equal expected, @hash
  end

  test 'should remove one key from nested hash' do
    @hash.sanitize!(:user => :type)

    expected = {:user => {:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}
    assert_equal expected, @hash
  end

  test 'should preserve one key from nested hash' do
    @hash.sanitize_except!(:user => :type)
    expected = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}}}}
    assert_equal expected, @hash
  end

  test 'should remove two keys from nested hash' do
    @hash.sanitize!(:user => [:type, :photo])
    expected = {:user => {:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}
    assert_equal expected, @hash
  end

  test 'should preserve two keys from nested hash' do
    @hash.sanitize_except!(:user => [:type, :photo])
    expected = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg'}}
    assert_equal expected, @hash
  end

  test 'should remove one key in deep nested hash' do
    @hash.sanitize!(:user => {:type => {:admin => :login}})
    expected = {:user => {:type => {:admin => {:email => 'slawosz@gmail.com',:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}
    assert_equal expected, @hash
  end

  test 'should preserve one key in deep nested hash' do
    @hash.sanitize_except!(:user => {:type => {:admin => :login}})
    expected = {:user => {:type => {:admin => {:login => 'slawosz'}}}}
    assert_equal expected, @hash
  end

  test 'should remove two keys in deep nested hash' do
    @hash.sanitize!(:user => {:type => {:admin => [:login, :email]}})
    expected = {:user => {:type => {:admin => {:password => 'secret'}},:photo => 'slawosz.jpg',:job => 'developer'},:url => 'slawosz.github.com',:language => 'ruby'}
    assert_equal expected, @hash
  end

  test 'should preserve two keys in deep nested hash' do
    @hash.sanitize_except!(:user => {:type => {:admin => [:login, :email]}})
    expected = {:user => {:type => {:admin => {:login => 'slawosz',:email => 'slawosz@gmail.com'}}}}
    assert_equal expected, @hash
  end

  test 'sanitize_except! should return modified receiver' do
    hash = {:foo => 1, :bar => 2}

    result = hash.sanitize_except!(:foo)
    expected = {:foo => 1}
    assert_equal expected, result
  end

  test 'sanitize! should return modified receiver' do
    hash = {:foo => 1, :bar => 2}

    result = hash.sanitize!(:foo, :bara)
    expected = {:bar => 2}
    assert_equal expected, result
  end

end

