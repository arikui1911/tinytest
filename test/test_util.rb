require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'test')
require 'tinytestutil'
require 'tinytest/util'

class TC_util < Test::Unit::TestCase
  def testdata
    @testdata ||= TinyTestUtil.load_data(__FILE__)
  end
  
  def test_filter_backtrace
    backtrace = TinyTestUtil.expand(testdata[:filter_backtrace_org])
    expected = TinyTestUtil.expand(testdata[:filter_backtrace_filtered])
    assert_equal expected, TinyTest::Util.filter_backtrace(backtrace)
  end
  
  def test_filter_backtrace_all_of_backtrace_concern_to_tinytest
    backtrace = TinyTestUtil.expand(testdata[:filter_backtrace_all_unit])
    assert_equal backtrace, TinyTest::Util.filter_backtrace(backtrace)
  end
  
  def test_filter_backtrace_first_of_backtrace_concern_to_tinytest
    backtrace = TinyTestUtil.expand(testdata[:filter_backtrace_unit_start_org])
    expected = TinyTestUtil.expand(testdata[:filter_backtrace_unit_start_filtered])
    assert_equal expected, TinyTest::Util.filter_backtrace(backtrace)
  end
  
  def test_measure_time
    TinyTestUtil.time_stopper do
      assert_equal 0, TinyTest::Util.measure_time{ sleep 0.5 }
    end
  end
  
  def test_compat_throw_exception
    assert_raise(NameError){
      TinyTest::Util.compat_throw_exception{ throw :hoge }
    }
    begin
      TinyTest::Util.compat_throw_exception{ throw :piyo }
    rescue NameError => ex
      assert_equal :piyo, ex.name
    else
      flunk 'NameError nothing'
    end
  end
  
  def test_refer_to_throw
    begin
      throw :foo
    rescue => ex
      assert TinyTest::Util.exception_refer_to_throw?(ex)
    else
      flunk
    end
    begin
      abc
    rescue => ex
      assert !TinyTest::Util.exception_refer_to_throw?(ex)
    else
      flunk
    end
  end
  
  class TC_OutputProxy < Test::Unit::TestCase
    def setup
      @buf = ''
      @out = TinyTest::Util::OutputProxy.new(@buf)
    end
    
    def test_print
      @out.print 'PRINT'
      assert_equal 'PRINT', @buf
    end
    
    def test_print_no_args
      @out.print
      assert_equal '', @buf
    end
    
    def test_print_multi_args
      @out.print 'PRINT', 'CALL'
      assert_equal 'PRINTCALL', @buf
    end
    
    def test_puts
      @out.puts 'PUTS'
      assert_equal "PUTS\n", @buf
    end
    
    def test_puts_no_args
      @out.puts
      assert_equal "\n", @buf
    end
    
    def test_puts_multi_args
      @out.puts 'PUTS', 'CALL'
      assert_equal "PUTS\nCALL\n", @buf
    end
    
    def test_printf
      n = rand(123)
      @out.printf "===%06d===", n
      assert_equal "===#{n.to_s.rjust(6, '0')}===", @buf
    end
    
    def test_escape_sync
      f = Struct.new(:sync).new
      f.sync = false
      vals = []
      out = TinyTest::Util::OutputProxy.new(f)
      ret = out.escape_sync(true){
        vals << f.sync
        'YIELD'
      }
      vals << ret << f.sync
      assert_equal [true, 'YIELD', false], vals
    end
  end
end


__END__
:filter_backtrace_org:
- lib/autotest.rb:571:in `add_exception'
- test/test_autotest.rb:62:in `test_add_exception'
- ./lib/mini/test.rb:165:in `__send__'
- ./lib/mini/test.rb:165:in `run_test_suites'
- ./lib/mini/test.rb:161:in `each'
- ./lib/mini/test.rb:161:in `run_test_suites'
- ./lib/mini/test.rb:158:in `each'
- ./lib/mini/test.rb:158:in `run_test_suites'
- ./lib/mini/test.rb:139:in `run'
- ./lib/mini/test.rb:106:in `run'
- ./lib/mini/test.rb:29
- test/test_autotest.rb:422
:filter_backtrace_filtered:
- lib/autotest.rb:571:in `add_exception'
- test/test_autotest.rb:62:in `test_add_exception'
:filter_backtrace_all_unit:
- ./lib/mini/test.rb:165:in `__send__'
- ./lib/mini/test.rb:165:in `run_test_suites'
- ./lib/mini/test.rb:161:in `each'
- ./lib/mini/test.rb:161:in `run_test_suites'
- ./lib/mini/test.rb:158:in `each'
- ./lib/mini/test.rb:158:in `run_test_suites'
- ./lib/mini/test.rb:139:in `run'
- ./lib/mini/test.rb:106:in `run'
- ./lib/mini/test.rb:29
:filter_backtrace_unit_start_org:
- ./lib/mini/test.rb:165:in `__send__'
- ./lib/mini/test.rb:165:in `run_test_suites'
- ./lib/mini/test.rb:161:in `each'
- ./lib/mini/test.rb:161:in `run_test_suites'
- ./lib/mini/test.rb:158:in `each'
- ./lib/mini/test.rb:158:in `run_test_suites'
- ./lib/mini/test.rb:139:in `run'
- ./lib/mini/test.rb:106:in `run'
- ./lib/mini/test.rb:29
- -e:1
:filter_backtrace_unit_start_filtered:
- -e:1
