DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  subj_id INTEGER NOT NULL,
  parent_id INTEGER,
  author_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (subj_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Barry', 'Bluejeans'),
  ('Magnus', 'Burnsides');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('How is babby formed?', 'how girl get pragnent', (SELECT id FROM users WHERE fname = 'Barry' AND lname = 'Bluejeans')),
  ('Are rollercoasters good for you?', 'liek for your body', (SELECT id FROM users WHERE fname = 'Magnus' AND lname = 'Burnsides'));

INSERT INTO
  question_follows (question_id, author_id)
VALUES
  (1, 1),
  (2, 1),
  (1, 2),
  (2, 2);

INSERT INTO
  replies (subj_id, parent_id, author_id, body)
VALUES
  (1, NULL, 2, 'Babby is formed by stork'),
  (1, 1, 2, 'U sure? Me wife thank you');

INSERT INTO
  question_likes (question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 1);
