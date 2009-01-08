#!ruby -w

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/unit'

module TinyTest::AttachedAssertions
  def assert_false(cond, message = nil)
    assertion_delegate(cond == false, message) do
      "Must Be False!"
    end
  end
end

class TC_hoge < TinyTest::TestCase
  def setup
    @str = 'hoge'
  end
  
  def test_size
    assert 4 == @str.size
  end
  
  def test_response
    assert_respond_to @str, :gsub
  end
  
  def test_empty
    assert_empty []
  end
  
  def test_raise
    assert_raise(ZeroDivisionError){ 123 / 0 }
  end
  
  def test_send
    assert_send ['', :empty?]
  end
  
  def test_throw
    assert_throws :hoge do
      throw :hogeee
    end
  end
  
  def test_myassertion
    assert_false 1 == 2
  end
  
  def test_myassertion_failure
    assert_false 1 == 1
  end
end

TinyTest::Unit.autorun
