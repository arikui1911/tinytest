# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 
# 
# This file does mockey-patching to built-in classes
# in order to insure backward compatibilities of Ruby.
# 
# There are some modification only to drive TinyTest.

class Module
  CALLER_RE = /\A(.+):(\d+)(?::in `(.+)'|\Z)/ #'
  
  METHOD_ADDED_RECORDS = {}
  
  def method_added(name)
    filename, lineno = caller[0].match(CALLER_RE).captures
    lineno = Integer(lineno)
    METHOD_ADDED_RECORDS[name] = [filename, lineno]
  end
end

class Method
  def source_location
    ::Module::METHOD_ADDED_RECORDS[name.intern]
  end
end

class Object
  def define_singleton_method(*args, &block)
    (class << self ; self ; end).class_eval{ define_method(*args, &block) }
  end
end

class Proc
  alias === call
  alias yield call
end
