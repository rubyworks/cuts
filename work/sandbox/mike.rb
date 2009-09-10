class Module
  private
  
  # Stash all current methods in a module and add that module to
  # the hierarchy. Permits insertion of new modules "in front" of
  # the module itself so we can override methods using 'include'
  def inherit_from_self!
    stash = Module.new
    instance_methods(false).each do |name|
      # Copy method into the module
      method = instance_method(name)
      stash.send(:define_method, name) do |*args|
        method.bind(self).call(*args[0...method.arity])
      end
      # Redefine our method to delegate upwards
      define_method(name) { super }
    end
    include stash
  end
  
  # Includes a module but places it in front of this module's
  # own methods. The mixin can use 'super' to refer to this module
  def include_in_front(mixin)
    inherit_from_self!
    include mixin
  end
  
  # A more fine-grained approach: overrides a single method and
  # allows you to refer to the old one using 'super'
  def override(name, &block)
    current = Module.new
    method = instance_method(name)
    current.send(:define_method, name) do |*args|
      method.bind(self).call(*args[0...method.arity])
    end
    
    include current
    define_method(name, &block)
  end
end
 
 
# Example: make a class and a module, mix the module into the
# class and use 'super' to refer to the class's method from the
# mixin. Ordinarily, the class's methods would take precedence
# over those from the module
 
class Foo
  def initialize(name)
    @name = name
  end
  
  def foo
    @name.upcase
  end
end
 
puts Foo.new('Mike').foo
#=> "MIKE"
 
module Helper
  def foo(thing)
    "My name is #{super}! I like #{thing}"
  end
end
 
class Foo
  include_in_front Helper
end
 
puts Foo.new('Mike').foo('Ruby!')
#=> "My name is MIKE! I like Ruby!"
 
 
# Second example, using override
 
class Bar
  def talk(item)
    "It's some #{item}"
  end
  
  override :talk do
    super.upcase
  end
end
 
puts Bar.new.talk('stuff')
#=> "IT'S SOME STUFF"
