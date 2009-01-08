# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'tinytest/assertions'

module TinyTest
  # User defines original assertions to AttachedAssertions or
  # implements original assertions to some modules and makes
  # AttachedAssertions include these.
  # 
  module AttachedAssertions
    def self.include_table
      @include_table ||= {}
    end
    private_class_method :include_table
    
    # Extended include.
    #
    def self.include(*modules)
      modules.each{|m| include_table[m] = true }
      super
    end
    
    # Check received Method object is owned or not
    # by AttachedAssertions and its including modules.
    # 
    def self.own?(method)
      return true if method.owner == self
      modules = include_table.keys
      modules.find{|mod| method.owner == mod } ? true : false
    end
    
    # ...
    def refer_to_assertion?(backtrace_line)
      meth = get_method_from_backtrace_line(backtrace_line) or return false
      Assertions == meth.owner || AttachedAssertions.own?(meth)
    end
  end
end
