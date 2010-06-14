# PhpSession
require 'php_session_parser'
require 'active_record'

class PhpSession < ActiveRecord::SessionStore::Session
  ##
  # :singleton-method:
  # The last-modified-time field defaults to 'last_active'.
  cattr_accessor :last_active_column
  @@last_active_column = 'last_active'

  before_save :set_last_active!

  class << self
    def marshal(data)
      data.to_php_session if data
    end

    def unmarshal(data)
      PHPSessionParser.new(data).hash if data
    end
  end

  private
    def set_last_active!
      return false if !loaded?
      write_attribute(@@last_active_column, Time.now.to_f)
    end
end
