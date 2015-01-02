require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    keys = []
    values = []

    params.each do |key, val|
      keys << key
      values << val
    end

    keys = keys.map {|k| "#{k} = ?"}.join(" AND ")

    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{keys}
    SQL

    parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...

  extend Searchable
end
