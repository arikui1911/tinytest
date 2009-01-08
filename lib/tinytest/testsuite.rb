# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

module TinyTest
  # ...
  class TestSuite
    # ...
    def initialize(testcase, testname)
      @testcase = testcase.new
      yield @testcase if block_given?
      @testcase.suite = self
      @testname = testname
      @n_assertions = nil
      @in_assertion_count_grouping = false
    end
    
    # ...
    def inspect
      "#{@testcase.class}##{@testname}"
    end
    
    # ...
    def run(runner)
      begin
        @testcase.setup
        @testcase.__send__(@testname)
        '.'
      ensure
        @testcase.teardown
      end
    rescue Exception => ex
      runner.receive_disorder(@testcase, @testname, ex)
    end
    
    # ...
    def count_assertions(&block)
      @n_assertions = 0
      yield
      @n_assertions
    end
    
    # ...
    def succ_assertion_count
      @n_assertions += 1 if @n_assertions unless @in_assertion_count_grouping
    end
    
    # ...
    def assertion_count_grouping
      @in_assertion_count_grouping = true
      @n_assertions += 1 if @n_assertions
      yield
    ensure
      @in_assertion_count_grouping = false
    end
  end
end
