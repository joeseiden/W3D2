class ModelBase

  TABLES = {
    'User' => 'users',
    'Question' => 'questions',
    'QuestionFollow' => 'question_follows',
    'Reply' => 'replies',
    'QuestionLike' => 'question_likes'
  }

  def self.all
    table =
    data = QuestionsDatabase.instance.execute("SELECT * FROM #{TABLES[itself.to_s]}")
    data.map { |datum| itself.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{TABLES[itself.to_s]}
      WHERE
        id = ?
    SQL

    return nil unless data.length > 0

    itself.new(data.first)
  end

  def save
    cols = self.instance_variables.map { |el| el.to_s.delete("@") }

    quest_marks = []
    self.instance_variables.drop(1).length.times { quest_marks << "?"}
    vals = "(#{quest_marks.join(", ")})"

    if id.nil?
      cols = cols[0...-1]
      QuestionsDatabase.instance.execute(<<-SQL, cols)

        INSERT INTO
          #{TABLES[self.class.to_s]} (#{cols})
        VALUES
          #{vals}
      SQL

      id = QuestionsDatabase.instance.last_insert_row_id
    else
      set_vals = self.instance_variables[0...-1].map{ |v| "#{v} = ?" }.join(", ").delete("@")
      QuestionsDatabase.instance.execute(<<-SQL, cols)
        UPDATE
          #{TABLES[self.class.to_s]}
        SET
          #{set_vals}
        WHERE
          id = ?
      SQL
    end
  end

  def self.where(options)
    query = []
    options.each do |k, v|
      query << "#{k} = ?"
    end
    query = query.join(" AND ")

    cols = options.values
    data = QuestionsDatabase.instance.execute(<<-SQL, cols)
      SELECT
        *
      FROM
        #{TABLES[itself.to_s]}
      WHERE
        #{query}
    SQL

    return nil unless data.length > 0

    data.map { |datum| itself.new(datum) }
  end

end
