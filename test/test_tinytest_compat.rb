require 'test/unit'
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'tinytest/compat' unless RUBY_VERSION >= '1.9.1'

class TC_compat < Test::Unit::TestCase
  def test_method_source_location
    expected = [__FILE__, __LINE__.pred]
    assert_equal expected, method(__method__).source_location
  end
  
  def test_object_define_singleton_method
    o = Object.new
    o.define_singleton_method :singleton do
      "SINGLETON"
    end
    assert_equal "SINGLETON", o.singleton
  end
  
  def test_proc_tri_equal
    func = lambda{|x| x * 10 }
    assert_equal func === 2, 20
  end
  
  def test_proc_yield
    func = lambda{|x| x * 10 }
    assert_equal func.yield(2), 20
  end
end
