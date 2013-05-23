require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/riddl/client')
require 'xml/smart'

class TestProp <  MiniTest::Unit::TestCase
  include ServerCase

  SERVER = File.expand_path(File.dirname(__FILE__) + '/../examples/properties/description.rb') 
  SCHEMA = File.expand_path(File.dirname(__FILE__) + '/../examples/properties/properties.xml') 
  NORUN = false

  def test_properties
    props = Riddl::Client.new(@url,SCHEMA)

    test = props.resource("/values/state")
    status, res = test.get
    assert status == 200
    assert res.length == 1

    if res[0].value == 'running'
      status, res = test.put [ Riddl::Parameter::Simple.new("value","stopped") ]; assert status == 200
      status, res = test.put [ Riddl::Parameter::Simple.new("value","stopped") ]; assert status == 404
    else  
      status, res = test.put [ Riddl::Parameter::Simple.new("value","running") ]; assert status == 200
      status, res = test.put [ Riddl::Parameter::Simple.new("value","running") ]; assert status == 404
    end

    test = props.resource("/values")
    status, res = test.get
    assert status == 200
    assert res.length == 1
    
    doc = XML::Smart.open(res[0].value)
    assert doc.find('/xmlns:properties/xmlns:property[.="name"]').any?
    assert doc.find('/xmlns:properties/xmlns:property[.="description"]').any?
    assert doc.find('/xmlns:properties/xmlns:property[.="dataelements"]').any?

    if doc.find('/xmlns:properties/xmlns:property[.="transformation"]').any?
      test = props.resource("/values/transformation")
      status, res = test.delete; assert status == 200
      test = props.resource("/values")
      status, res = test.post [ Riddl::Parameter::Simple.new("name","transformation"), Riddl::Parameter::Simple.new("value","xxx") ]; assert status == 200
    else
      test = props.resource("/values")
      status, res = test.post [ Riddl::Parameter::Simple.new("name","transformation"), Riddl::Parameter::Simple.new("value","xxx") ]; assert status == 200
    end

    test = props.resource("/values/dataelements/c")
    status, res = test.get
    if status == 404
      test = props.resource("/values/dataelements")
      status, res = test.post [ Riddl::Parameter::Simple.new("value","<c>hallo</c>") ]; assert status == 200
    elsif status == 200
      test = props.resource("/values/dataelements/c")
      status, res = test.delete; assert status == 200
      test = props.resource("/values/dataelements")
      status, res = test.post [ Riddl::Parameter::Simple.new("value","<c>hallo</c>") ]; assert status == 200
    else
      assert false
    end

    test = props.resource("/values/dataelements/c")
    status, res = test.put [ Riddl::Parameter::Simple.new("value","foo") ]; assert status == 200

    test = props.resource("/values/name")
    status, res = test.put [ Riddl::Parameter::Simple.new("value","juergen") ]; assert status == 500
  end
end
