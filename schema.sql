CREATE TABLE expenses (
  id serial PRIMARY KEY,
  name text NOT NULL,
  amount numeric(10,2) NOT NULL,
  date date NOT NULL DEFAULT NOW(),
  category_id int NOT NULL REFERENCES categories(id) 
);

CREATE TABLE categories (
  id serial PRIMARY KEY,
  type text NOT NULL UNIQUE
);

CREATE TABLE expense_limit (
  id serial PRIMARY KEY,
  value numeric(10,2) NOT NULL DEFAULT 1000.00
);
