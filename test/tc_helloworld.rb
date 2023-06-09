require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/ruby/riddl/wrapper')

class TestHelloWorld <  Minitest::Test

  def test_hw
    riddl = Riddl::Wrapper.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/helloworld/declaration.xml')
    )

    assert riddl.declaration?
    assert riddl.validate!
    assert riddl.declaration.description_xml == File.read(
      File.expand_path(File.dirname(__FILE__) + '/../examples/helloworld/declaration-definition_goal.xml')
    )
  end
end
