require "pg"

class DatabasePersistence
  attr_reader :limit

  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['HEROKU_POSTGRESQL_GOLD_URL'])
          else
            PG.connect(dbname: "expense_tracker")
          end

    @logger = logger
    @limit = fetch_limit || 1000.00
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def all_expenses
    sql = <<~SQL
      SELECT e.id,
             e.name,
             e.amount,
             e.date,
             c.type
        FROM expenses e
        INNER JOIN categories c
        ON e.category_id = c.id;
    SQL
    result = query(sql)

    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        name: tuple["name"],
        amount: tuple["amount"].to_f,
        date: tuple["date"],
        category: tuple["type"]
      }
    end
  end

  def add_expense(name, amount, category_id)
    sql = "INSERT INTO expenses (name, amount, category_id) VALUES ($1, $2, $3)"
    query(sql, name, amount, category_id)
  end
  
  def delete_expense(id)
    sql = "DELETE FROM expenses WHERE id = $1"
    query(sql, id)
  end
  
  def total_amount
    sql = "SELECT SUM(amount) FROM expenses"
    query(sql).first["sum"].to_i
  end
  
  def all_categories
    sql = "SELECT * FROM categories"
    result = query(sql)

    result.map do |tuple|
      {
        id: tuple["id"],
        name: tuple["type"]
      }
    end
  end

  def add_category(name)
    sql = "INSERT INTO categories (type) VALUES ($1)"
    query(sql, name)
  end

  def total_categories
    sql = "SELECT COUNT(id) FROM categories"
    query(sql).first["count"].to_f
  end

  def limit=(number)
    @limit = number
    sql = "INSERT INTO expense_limit (value) VALUES ($1)"
    query(sql, number)
  end

  def disconnect
    @db.close
  end

  private

  def fetch_limit
    sql = "SELECT value FROM expense_limit ORDER BY id DESC LIMIT 1"
    result = query(sql)
    result.first["value"].to_f if result.any?
  end
end