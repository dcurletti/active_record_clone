require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  @table_name = nil

  def self.columns
    if @columns
      @columns
    else
      column_names = DBConnection.execute2("SELECT * FROM #{self.table_name}")
      @columns = column_names.first.map(&:to_sym)
      @columns
    end
  end

  def self.finalize!
    columns.each do |column|

      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |argument| 
        self.attributes[column] = argument
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name 
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    records = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM  
      #{table_name}
    SQL

    parse_all(records)
  end

  def self.parse_all(results)
    answer = []
    results.each do |result|
      answer << self.new(result)
    end
    answer 
  end

  def self.find(id)
    record = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    parse_all(record).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      name = attr_name.to_sym
      if self.class.columns.include?(name)
        send("#{name}=", value)
      else
        raise "unknown attribute '#{attr_name}'" 
      end
    end
  end

  def attributes
    # @attributes = @attributes || {}
    @attributes || @attributes = {}
  end

  def attribute_values
    answer = []
    self.class.columns.map do |column|
      column = column.to_sym
      answer << self.send("#{column}")
    end

    answer
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.count).join(", ")
    p col_names
    p question_marks
    DBConnection.execute(<<-SQL, *attribute_values)

      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})

    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map { |col| "#{col} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end


