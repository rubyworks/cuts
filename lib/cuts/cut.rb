# cut.rb
# Copyright (c) 2005,2008 Thomas Sawyer
#
# Ruby License
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the same terms as Ruby.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.

# = Cut
#
# Cuts are transparent subclasses. Thay are the basis of
# Cut-based AOP. The general idea of Cut-based AOP is that
# the Cut can serve a clean container for customized advice on
# top of which more sophisticated AOP systems can be built.
#
# == Examples
#
# The basic usage is:
#
#   class X
#     def x; "x"; end
#   end
#
#   cut :Z < X do
#     def x; '{' + super + '}'; end
#   end
#
#   X.new.x  #=> "{x}"
#
# One way to use this in an AOP fashion is to define an aspect as a class
# or function module, and tie it together with the Cut.
#
#   module LogAspect
#     extend self
#     def log(meth, result)
#       ...
#     end
#   end
#
#   cut :Z < X do
#     def x
#       LogAspect.log(:x, r = super)
#       return r
#     end
#   end
#
# == Implementation
#
# Cuts act as a "pre-class". Which depictively is:
#
#   ACut < AClass < ASuperClass
#
# Instantiating AClass effecively instantiates ACut instead,
# but that action is effectively transparent.
#
# This particular implementation create a module for each cut
# and extends objects as they are created. Given the following example:
#
#   class Klass
#     def x; "x"; end
#   end
#
#   cut KlassCut < Klass
#     def x; '{' + super + '}'; end
#   end
#
# The effect is essentially:
#
#   k = Klass.new
#   k.extend KlassCut
#
#   p k.x
#
# The downside to this approach is a limitation in dynamicism.

class Cut < Module
  def initialize(klass, &block)
    klass.cuts.unshift(self)
    module_eval(&block)
  end
end

class Class
  def cuts
    @cuts ||= []
  end
end

class Object
  class << self
    alias_method :_new, :new

    def new(*a, &b)
      o = _new(*a, &b)
      if !cuts.empty?
        o.extend *cuts
      end
      o
    end

  end
end

class Symbol
  #alias :_op_lt_without_cuts :<

  # A little tick to simulate subclassing literal syntax.
  def <(klass)
    if Class === klass
      [self, klass]
    else
      raise NoMethodError, "undefined method `<' for :#{self}:Symbol"
      #_op_lt_without_cuts(cut_class)
    end
  end
end

module Kernel
  # Cut convienence method.
  def cut(klass, &block)
    case klass
    when Array
      name, klass = *klass
    else
      name = nil
    end

    cut = Cut.new(klass, &block)

    # How to handle main, but not other instance spaces?
    #klass.modspace::const_set(klass.basename, cut)
    mod = (Module === self ? self : Object)
    mod.const_set(name, cut) if name  # <<- this is what we don't have in Cut.new

    return cut
  end
end


