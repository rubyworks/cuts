require 'microtest'
require 'ae'
require 'cuts'

class AOPTest < MicroTest::TestCase

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

  def setup
    @x1 = X.new
  end

  def test_class
    @x1.class.assert == X
  end

  def test_public_methods
    meths = @x1.public_methods(false)
    meths = meths.map{ |m| m.to_s }
    meths.assert.include?("y")
    meths.assert.include?("q")
    meths.assert.include?("x")
  end

  def test_x
    @x1.x.assert == "{x}"
  end

  def test_y
    @x1.y.assert == "y"
  end

  def test_q
    @x1.q.assert == "<{x}>"
  end

end
