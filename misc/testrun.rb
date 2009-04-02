$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/unit'

TinyTest::Unit.autorun

class Hoge
  def hoge
    raise 'hoge raises, hogehoge'
  end
end

class TC_hoge < TinyTest::TestCase
  def test_block
    assert_block{ 123 }
    refute_block{ nil }
  end
  
  def test_equal
    assert_equal 4, 'Ruby'.size
    refute_equal 4, 'Python'.size
  end
  
  def test_delta
    assert_in_delta 1, 1
    refute_in_delta 1, 3
  end
  
  def test_epsilon
    assert_in_epsilon 1, 1
    refute_in_epsilon 1, 10
  end
  
  def test_response
    assert_respond_to '', :intern
    refute_respond_to //, :intern
  end
  
  def test_empty
    assert_empty []
    refute_empty [1]
  end
  
  def test_include
    assert_includes [1, 2, 3], 2
    refute_includes %w[a b c], 'z'
  end
  
  def test_instance
    assert_instance_of String, ''
    refute_instance_of String, 123
  end
  
  def test_kind_of
    assert_kind_of Integer, 123
    refute_kind_of Integer, 123.0
  end
  
  def test_match
    assert_match /\A[A-Z]/, 'Hoge'
    refute_match /\A[A-Z]/, 'hoge'
  end
  
  def test_same
    assert_same :hoge, :hoge
    refute_same 'hoge', 'hoge'
  end
  
  def test_send
    assert_send ['Hoge', :slice, /\A[A-Z]/]
    refute_send ['aaa', :empty?]
  end
  
  def test_throws
    assert_throws(:hoge){|t| throw t }
    refute_throws(:hoge){}
  end
  
  def test_raises_a
    assert_raises(ZeroDivisionError, TypeError){ 1 / 0 }
  end
  
  def test_raises_r
    refute_raises(ZeroDivisionError){ 1 / 0.0 }
  end
end

