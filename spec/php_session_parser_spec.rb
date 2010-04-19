require 'rubygems'
require 'spec'
require 'php_session_parser'

require File.dirname(__FILE__) + '/spec_helper'

describe PHPSessionParser do
  it 'should parse PHP session encodings' do
    session = PHPSessionParser.new('count|i:4;name|s:4:"hoge";return_to|a:2:{s:6:"action";s:4:"show";s:10:"controller";s:4:"cart";}').hash
    session.should == {"count" => 4, "name" => "hoge", "return_to" => {"action" => "show", "controller" => "cart"}}
  end
end

describe Hash do
  it 'should be encoded as PHP session encodings' do
    session = {"count" => 4, "name" => "hoge", "return_to" => {"action" => "show", "controller" => "cart"}}
    session.to_php_session.should == 'count|i:4;name|s:4:"hoge";return_to|a:2:{s:6:"action";s:4:"show";s:10:"controller";s:4:"cart";}'
  end
end

describe String do
  it "should be serialized in PHP's data serialization format" do
    "hoge".php_serialize.should == 's:4:"hoge";'
  end
end

describe Integer do
  it "should be serialized in PHP's data serialization format" do
    1234.php_serialize.should == 'i:1234;'
  end
end

describe Float do
  it "should be serialized in PHP's data serialization format" do
    123.456.php_serialize.should == 'd:123.456;'
  end
end

describe Hash do
  it "should be serialized in PHP's data serialization format" do
    {"hoge" => 1, "fuga" => "piyo"}.php_serialize.should == 'a:2:{s:4:"fuga";s:4:"piyo";s:4:"hoge";i:1;}'
  end
end

describe Array do
  it "should be serialized in PHP's data serialization format" do
    [1, "hoge"].php_serialize.should == 'a:2:{i:0;i:1;i:1;s:4:"hoge";}'
  end
end

describe Symbol do
  it "should be serialized in PHP's data serialization format" do
    :hoge.php_serialize.should == 's:4:"hoge";'
  end
end

describe NilClass do
  it "should be serialized in PHP's data serialization format" do
    nil.php_serialize.should == 'N;'
  end
end

describe TrueClass do
  it "should be serialized in PHP's data serialization format" do
    true.php_serialize.should == 'b:1;'
  end
end

describe FalseClass do
  it "should be serialized in PHP's data serialization format" do
    false.php_serialize.should == 'b:0;'
  end
end
