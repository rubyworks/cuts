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
#   cut :C < X do
#     def x; '{' + super + '}'; end
#   end
#
#   X.new.x  #=> "{x}"
#
# To use this in an AOP fashion you can define an Aspect, as a class
# or function module, and tie it together with the Cut.
#
#   module LogAspect
#     extend self
#     def log(meth, result)
#       ...
#     end
#   end
#
#   cut :C < X do
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
# This is the basic model of this particluar implementation:
#
#   class Klass
#     def x; "x"; end
#   end
#
#   cut KlassCut < Klass
#     def x; '{' + super + '}'; end
#   end
#
# We cut it like so:
#
#   Klass = KlassCut
#
#   p Klass.new.x
#
# This is simple and relatvely robust, but not 100% transparent.
# So we add some redirection methods to the cut to improve the
# transparency.
#
# Due to limitation in meta-programming Ruby as this level, the
# transparency isn't perfect, but it's fairly close.

class Cut

  def self.new(klass, &block)
    cut = Class.new(klass, &block)  # <-- This is the actual cut.

    #cut.class_eval(&block)

    cut.send(:include, Transparency)
    cut.extend MetaTransparency

    v = $VERBOSE
    $VERBOSE = false
    klass.modspace::const_set(klass.basename, cut)
    $VERBOSE = v

    return cut
  end

  # These methods are needed to emulate full transparancy as
  # closely as possible.

  module Transparency
    def methods(all=true)
      self.class.superclass.instance_methods(all)
    end
    def public_methods(all=true)
      self.class.superclass.public_instance_methods(all)
    end
    def private_methods(all=true)
      self.class.superclass.private_instance_methods(all)
    end
    def protected_methods(all=true)
      self.class.superclass.protected_instance_methods(all)
    end
  end

  # These methods are needed to emulate full transparancy as
  # closely as possible.

  module MetaTransparency
    #def instance_method(name) ; p "XXXX"; superclass.instance_method(name) ; end
    def define_method(*a,&b) ; superclass.define_method(*a,&b) ; end
    def module_eval(*a,&b)   ; superclass.module_eval(*a,&b)   ; end
    def class_eval(*a,&b)    ; superclass.class_eval(*a,&b)    ; end
  end

end


class Symbol
  #alias :_op_lt_without_cuts :<

  # A little tick to simulate subclassing literal syntax.

  def <(klass)
    if Class === klass
      [self,klass]
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
    mod.const_set(name, cut) if name # <<- this is what we don't have in Cut.new

    return cut
  end
end

class Module
  # Returns the root name of the module/class.
  #
  #   module Example
  #     class Demo
  #     end
  #   end
  #
  #   Demo.name       #=> "Example::Demo"
  #   Demo.basename   #=> "Demo"
  #
  # For anonymous modules this will provide a basename
  # based on Module#inspect.
  #
  #   m = Module.new
  #   m.inspect       #=> "#<Module:0xb7bb0434>"
  #   m.basename      #=> "Module_0xb7bb0434"
  # 
  def basename
    if name and not name.empty?
      name.gsub(/^.*::/, '')
    else
      nil #inspect.gsub('#<','').gsub('>','').sub(':', '_')
    end
  end

  # Returns the module's container module.
  #
  #   module Example
  #     class Demo
  #     end
  #   end
  #
  #   Example::Demo.modspace   #=> Example
  #
  # See also Module#basename.
  #
  def modspace
    space = name[ 0...(name.rindex( '::' ) || 0)]
    space.empty? ? Object : eval(space)
  end
end

