require 'sqlite3'
require 'singleton'

require_relative 'model_base'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

class User < ModelBase

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM users")
  #   data.map { |datum| User.new(datum) }
  # end
  #
  # def self.find_by_id(id)
  #   user = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       users
  #     WHERE
  #       id = ?
  #   SQL
  #
  #   return nil unless user.length > 0
  #
  #   User.new(user.first)
  # end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    return nil unless user.length > 0

    User.new(user.first)
  end

  attr_reader :table
  attr_accessor :id, :fname, :lname

  def initialize(options)
    @fname = options['fname']
    @lname = options['lname']
    @id = options['id']
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_author_id(self.id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
      CAST(COUNT(user_id) AS FLOAT) /
      COUNT(DISTINCT(question_id))
      FROM
        question_likes
      LEFT JOIN
        questions ON question_likes.question_id = questions.id
      WHERE
        questions.author_id = ?
      GROUP BY
        question_id
    SQL

    return nil unless data.length > 0

    data.first
  end

  # def save
  #   if id.nil?
  #     QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
  #       INSERT INTO
  #         users (fname, lname)
  #       VALUES
  #         (?, ?)
  #     SQL
  #
  #     id = QuestionsDatabase.instance.last_insert_row_id
  #   else
  #     QuestionsDatabase.instance.execute(<<-SQL, fname, lname, id)
  #       UPDATE
  #         users
  #       SELECT
  #         fname = ?, lname = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   end
  # end

end

class Question < ModelBase

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    return nil unless question.length > 0

    Question.new(question.first)
  end

  def self.find_by_title(title)
    title = "%#{title}%"
    questions = QuestionsDatabase.instance.execute(<<-SQL, title)
      SELECT
        *
      FROM
        questions
      WHERE
        title LIKE ?
    SQL

    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end

  def self.find_by_body(body)
    body = "%#{body}%"
    questions = QuestionsDatabase.instance.execute(<<-SQL, body)
      SELECT
        *
      FROM
        questions
      WHERE
        body LIKE ?
    SQL

    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_reader :table
  attr_accessor :id, :author_id, :title, :body

  def initialize(options)
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
    @id = options['id']
  end

  def author
    User.find_by_id(self.author_id)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def save
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
        INSERT INTO
          questions(title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL

      id = QuestionsDatabase.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id, id)
        UPDATE
          questions
        SET
          title = ?, body = ?, author_id = ?
        WHERE
          id = ?
      SQL
    end
  end

end

class QuestionFollow < ModelBase

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollow.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL

    return nil unless question.length > 0
    Question.new(question.first)
  end

  def self.find_by_question_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        question_id = ?
    SQL

    return nil unless question.length > 0
    Question.new(question.first)
  end

  def self.find_by_user_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        user_id = ?
    SQL

    return nil unless questions.length > 0
    questions.map { |question| Question.new(question) }
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_follows
      JOIN
        users on question_follows.user_id = users.id
      WHERE
        question_id = ?
    SQL

    return nil unless users.length > 0
    users.map { |user| User.new(user) }
  end

  def self.followed_questions_for_user_id(user_id)
    f_questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        question_follows
      JOIN
        questions on question_follows.question_id = questions.id
      WHERE
        user_id = ?
    SQL

    return nil unless f_questions.length > 0
    f_questions.map { |fq| Question.new(fq) }
  end

  def self.most_followed_questions(n)
    mf_q = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        DISTINCT *
      FROM
        questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
      GROUP BY
        question_id
      ORDER BY
        COUNT(*)
      LIMIT
        ?
    SQL

    return nil unless mf_q.length > 0

    mf_q.map { |question| Question.new(question) }
  end

  def self.sub_query
    QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      DISTINCT COUNT(*)
    FROM
      question_follows
    GROUP BY
      question_id
    SQL
  end

  attr_reader :table
  attr_reader :id, :question_id, :user_id

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
    @id = options['id']
  end



end

class Reply < ModelBase

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL

    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def self.find_by_question_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def self.find_by_parent_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL

    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def self.find_by_author_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL

    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def self.find_by_body(body)
    body = "%#{body}%"
    reps = QuestionsDatabase.instance.execute(<<-SQL, body)
      SELECT
        *
      FROM
        replies
      WHERE
        body LIKE ?
    SQL

    return nil unless reps.length > 0

    reps.map { |rep| Reply.new(rep) }
  end

  attr_reader :table
  attr_accessor :body, :id, :question_id, :parent_id, :author_id

  def initialize(options)
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @author_id = options['author_id']
    @body = options['body']
    @id = options['id']
  end

  def author
    User.find_by_id(self.author_id)
  end

  def question
    Question.find_by_id(self.question_id)
  end

  def parent_reply
    Reply.find_by_id(self.parent_id)
  end

  def child_replies
    Reply.find_by_parent_id(self.id)
  end

  def save
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_id, author_id, body)
        INSERT INTO
          replies(question_id, parent_id, author_id, body)
        VALUES
          (?, ?, ?, ?)
      SQL

      id = QuestionsDatabase.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_id, author_id, body, id)
        UPDATE
          replies
        SET
          question_id = ?, parent_id = ?, author_id = ?, body = ?
        WHERE
          id = ?
      SQL
    end
  end

end

class QuestionLike < ModelBase

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
  end


  def self.find_by_id(id)
    q_like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL

    return nil unless q_like.length > 0
    QuestionLike.new(q_like.first)
  end

  def self.find_by_question_id(id)
    q_like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL

    return nil unless q_like.length > 0
    QuestionLike.new(q_like.first)
  end

  def self.find_by_user_id(id)
    q_like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        user_id = ?
    SQL

    return nil unless q_like.length > 0
    QuestionLike.new(q_like.first)
  end

  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_likes
      JOIN
        users on question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL

    return nil unless users.length > 0
    users.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*)
      FROM
        question_likes
      JOIN
        users on question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL

    num_likes
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        question_likes
      JOIN
        questions on question_likes.question_id = questions.id
      WHERE
        user_id = ?
    SQL

    return nil unless questions.length > 0
    questions.map { |question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    ml_q = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        questions
      JOIN
        question_likes ON questions.id = question_likes.question_id
      GROUP BY
        question_id
      ORDER BY
        COUNT(*)
      LIMIT
        ?
    SQL

    return nil unless ml_q.length > 0
    ml_q.map { |q| Question.new(q) }
  end

  attr_reader :id, :question_id, :user_id, :table

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
    @id = options['id']
  end

end
