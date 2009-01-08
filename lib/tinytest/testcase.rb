# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

module TinyTest
  # ...
  class TestCase
    # ...
    def self.testcases_container_caller(&block)
      @testcases_container_caller = block
    end
    
    def self.inherited(subclass)
      subclass.testcases_container_caller(&@testcases_container_caller)
      @testcases_container_caller.call << subclass
    end
    private_class_method :inherited
    
    # ...
    def self.collect_tests
      tests = []
      public_instance_methods(true).each do |test|
        test = test.to_s
        tests << test if /\Atest/ =~ test
      end
      sort_my_tests(tests)
    end
    
    # ...
    def self.sort_my_tests(list)
      list.shuffle
    end
    
    # test API: describe preparation for tests
    def setup
    end
    
    # test API: describe cleaning up for tests
    def teardown
    end
  end
end
