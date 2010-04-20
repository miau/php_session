# PhpSession
require 'php_session_parser'
require 'active_record'

class PhpSession < ActiveRecord::SessionStore::SqlBypass
  ##
  # :singleton-method:
  # The last-modified-time field defaults to 'last_active'.
  cattr_accessor :last_active_column
  @@last_active_column = 'last_active'

  @@table_name = 'php_sessions'
  @@session_id_column = 'session_id'
  @@data_column = 'data'

  class << self
    def marshal(data)
      data.to_php_session if data
    end

    def unmarshal(data)
      PHPSessionParser.new(data).hash if data
    end
  end

  def save
    return false if !loaded?
    marshaled_data = self.class.marshal(data)

    if @new_record
      @new_record = false
      @@connection.update <<-end_sql, 'Create session'
        INSERT INTO #{@@table_name} (
          #{@@connection.quote_column_name(@@session_id_column)},
          #{@@connection.quote_column_name(@@data_column)},
          #{@@connection.quote_column_name(@@last_active_column)}
        ) VALUES (
          #{@@connection.quote(session_id)},
          #{@@connection.quote(marshaled_data)},
          #{@@connection.quote(Time.now.to_f)}
        )
      end_sql
    else
      @@connection.update <<-end_sql, 'Update session'
        UPDATE #{@@table_name}
        SET #{@@connection.quote_column_name(@@data_column)} = #{@@connection.quote(marshaled_data)},
            #{@@connection.quote_column_name(@@last_active_column)} = #{@@connection.quote(Time.now.to_f)}
        WHERE #{@@connection.quote_column_name(@@session_id_column)} = #{@@connection.quote(session_id)}
      end_sql
    end
  end
end
