require 'cuts/aop'

class X
  def x; "x"; end
  def y; "y"; end
  def q; "<" + x + ">"; end
end

Xa = Aspect.new do
  join :x do |jp|
    jp == :x
  end

  def x(target); '{' + target.super + '}'; end
end

X.apply(Xa)


@x1 = X.new

@x1.class.assert == X

meths = @x1.public_methods(false)
meths.assert.include?("y")
meths.assert.include?("q")
meths.assert.include?("x")

@x1.x.assert == "{x}"

@x1.y.assert == "y"

@x1.q.assert == "<{x}>"

