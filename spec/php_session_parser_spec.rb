require 'rubygems'
require 'spec'
require 'php_session_parser'

require File.dirname(__FILE__) + '/spec_helper'

describe PHPSessionParser do
  it 'should parse PHP session encodings' do
    session = PHPSessionParser.new('count|i:4;name|s:4:"hoge";return_to|a:2:{s:6:"action";s:4:"show";s:10:"controller";s:4:"cart";}').hash
    session.should == {:count => 4, :name => "hoge", :return_to => {"action" => "show", "controller" => "cart"}}
  end

  it 'should parse all types' do
    session = PHPSessionParser.new('integer|i:4;string|s:4:"hoge";array|a:2:{i:0;i;1;s:3:"key";s:5:"value";}float|d:123.456;nil|N;true|b:1;false|b:0').hash
    session.should == {:integer => 4, :string => "hoge", :array => {0 => 1, "key" => "value"}, :float => 123.456, :nil => nil, :true => true, :false => false}
  end

  it 'should parse long string' do
    len = 2 ** 16
    str = "a" * len
    session = PHPSessionParser.new(%Q[long_string|s:#{len}:"#{str}"]).hash
    session.should == {:long_string => str}
  end

  it 'should parse a marshalled object' do
    session = PHPSessionParser.new(%Q(obj|O:21:"_RubyMarshalledObject":1:{s:11:"_marshalled";s:106:"BAhJQzonQWN0aW9uQ29udHJvbGxlcjo6Rmxhc2g6OkZsYXNoSGFzaHsGOgpl\ncnJvciISRXJyb3IgbWVzc2FnZQY6CkB1c2VkewY7BkY=\n";})).hash
    session[:obj].class.should == ActionController::Flash::FlashHash
    session[:obj][:error].should == "Error message"
  end

  it 'should parse flash object and store it with a key "flash" not :flash' do
    session = PHPSessionParser.new(%Q(flash|O:21:"_RubyMarshalledObject":1:{s:11:"_marshalled";s:106:"BAhJQzonQWN0aW9uQ29udHJvbGxlcjo6Rmxhc2g6OkZsYXNoSGFzaHsGOgpl\ncnJvciISRXJyb3IgbWVzc2FnZQY6CkB1c2VkewY7BkY=\n";})).hash
    session["flash"].class.should == ActionController::Flash::FlashHash
    session["flash"][:error].should == "Error message"
  end

  it "should parse a PHP's array that has numeric keys as an Ruby's array" do
    session = PHPSessionParser.new('array_like_hash|a:2:{i:0;i:123;i:1;s:3:"abc";}').hash
    session.should == {:array_like_hash => [123, "abc"]}
  end

  it "should parse a empty PHP's array as a empty Ruby's hash" do
    session = PHPSessionParser.new('array_like_hash|a:0:{}').hash
    session.should == {:array_like_hash => {}}
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
    :hoge.php_serialize.should == %Q(O:21:"_RubyMarshalledObject":1:{s:11:"_marshalled";s:13:"BAg6CWhvZ2U=\n";})
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

describe Object do
  it "should be serialized in PHP's data serialization format" do
    flash = ActionController::Flash::FlashHash.new()
    flash[:error] = "Error message"
    flash.php_serialize.should == %Q(O:21:"_RubyMarshalledObject":1:{s:11:"_marshalled";s:106:"BAhJQzonQWN0aW9uQ29udHJvbGxlcjo6Rmxhc2g6OkZsYXNoSGFzaHsGOgpl\ncnJvciISRXJyb3IgbWVzc2FnZQY6CkB1c2VkewY7BkY=\n";})
  end
end
