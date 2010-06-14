# !/usr/bin/env ruby

# Copyright Easynet Belgium
# Licensed under the LGPL

class PHPSessionParser
  attr_reader :hash

  def initialize(str = "")
    @working_str = str
    @hash = update_hash(str)
  end

  def update_hash(str)
    new_hash = {}
    while more_data?
      var_name = extract_var_name
      type = extract_var_type.downcase
      if var_name and type
        key = (var_name == "flash") ? var_name : var_name.to_sym
        new_hash[key] = send("extract_#{type}")
      end
    end
    new_hash
  end

  def [](key)
    @hash[key]
  end

  def []=(key, val)
    @hash[key] = val
  end

  def more_data?
    @working_str and @working_str.length > 0
  end

  def extract_i
    value, @working_str = @working_str[@working_str.index(/\d/)..@working_str.length].split(/[;:]/, 2)
    value.to_i
  end

  def extract_d
    value, @working_str = @working_str[@working_str.index(/\d/)..@working_str.length].split(/[;:]/, 2)
    value.to_f
  end

  def extract_s
    length, @working_str = @working_str[1..@working_str.length].split(":", 2)
    value = @working_str[1..length.to_i]
    @working_str = @working_str.sub(@working_str[0..length.to_i+2], "")
    value
  end

  def extract_n
    value, @working_str = @working_str.split(/[;:]/, 2)
    nil
  end

  def extract_b
    value, @working_str = @working_str[@working_str.index(/[01]/)..@working_str.length].split(/[;:]/, 2)
    value == "1" ? true : false
  end

  def extract_var_name
    var_name = nil
    if index = @working_str.index(/\w/)
      var_name, @working_str = @working_str[index..@working_str.length].split("|", 2)
      var_name
    else
      @working_str = ""
    end
    return var_name
  end

  def extract_var_type
    index = nil
    if index = @working_str.index(/[aisdNbO]/)
      type, @working_str = @working_str[index..@working_str.length].split("", 2)
      type
    else
      @working_str = ""
    end
  end

  def extract_a
    ret = {}
    number_of_elements = @working_str[/\d+/]
    trash, @working_str = @working_str.split(number_of_elements, 2)
    might_be_array = true
    number_of_elements.to_i.times do |i|
      key_type = extract_var_type.downcase
      key = send("extract_#{key_type}")
      value_type = extract_var_type.downcase
      value = send("extract_#{value_type}")
      ret[key] = value
      if key != i
        might_be_array = false
      end
    end

    if ret.length > 0 && might_be_array
      # extracted data seems to be array
      return ret.keys.map{|key| ret[key]}
    end
    ret
  end

  def extract_o
    length, klass, @working_str = @working_str[1..@working_str.length].split(":", 3)
    if length != "21" || klass != '"_RubyMarshalledObject"'
      return {}
    end
    @working_str = ":" + @working_str
    marshalled = extract_a
    Marshal.load(ActiveSupport::Base64.decode64(marshalled["_marshalled"]))
  end
end

class Hash
  def to_php_session
    result = ""
    keys.sort_by{|key| key.to_s}.each do |key|
      value = self[key]
      result += "#{key}|#{value.php_serialize}"
    end
    result
  end
end

class String
  def php_serialize
    return super if self.class != String
#    puts "s:#{length}:\"#{self}\";"
    "s:#{length}:\"#{self}\";"
  end
end

class Integer
  def php_serialize
    return super if self.class != Bignum && self.class != Fixnum
    return "i:#{to_s};"
  end
end

class Float
  def php_serialize
    return super if self.class != Float
    return "d:#{to_s};"
  end
end

class Hash
  def php_serialize
    return super if self.class != Hash
#    puts "in hash"
    str = ""
    str += "a:#{length}:{"
    each_pair do |k, value|
      str += "#{k.php_serialize}#{value.php_serialize}"
    end
    str += "}"
    str
  end
end

class Array
  def php_serialize
    return super if self.class != Array
    str = ""
    str += "a:#{length}:{"
    each_index do |i|
      str += "#{i.php_serialize}#{at(i).php_serialize}"
    end
    str += "}"
    str
  end
end

class NilClass
  def php_serialize
    return "N;"
  end
end

class TrueClass
  def php_serialize
    return "b:1;"
  end
end

class FalseClass
  def php_serialize
    return "b:0;"
  end
end

class Object
  def php_serialize
    value = ActiveSupport::Base64.encode64(Marshal.dump(self)).php_serialize
    return %Q{O:21:"_RubyMarshalledObject":1:{s:11:"_marshalled";#{value}}}
  end
end
