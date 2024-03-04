require "sinatra"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload("database_persistence.rb")
end

helpers do
  def total_amount
    @storage.total_amount
  end

  def limit
    @storage.limit
  end
  
  def add_commas(number_string)
    integer_part, decimal_part = number_string.to_s.split('.')
  
    # Add commas to the integer part
    integer_with_commas = integer_part.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  
    # Ensure decimal_part has 2 decimal places
    decimal_part ||= "00"
    decimal_part = decimal_part.ljust(2, "0")
    decimal_part = decimal_part[0, 2]
  
    result = integer_with_commas
    result += ".#{decimal_part}"
  
    result
  end
end

def display_limit_message
  session[:limit_message] = "You have exceeded your limit." if total_amount > limit
end

# returns true for non-empty strings
def valid_string?(string)
  string.strip.size > 0
end

# matches strings that represent decimal numbers
def valid_dollar_amount?(number_string)
  number_string.match?(/\A\d+(\.\d+)?\z/)
end

def valid_expense?(name, amount, category)
  valid_string?(name) &&

  valid_dollar_amount?(amount) &&

  # check if category exists
  (1..@storage.total_categories).cover?(category.to_i)
end

def all_categories
  @storage.all_categories
end

before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  @expenses = @storage.all_expenses
  display_limit_message
  erb :main
end

get "/new" do
  @categories = all_categories
  erb :new
end

# record a new expense
post "/new/expense" do
  name = params[:name]
  amount = params[:amount]
  category = params[:category]

  if valid_expense?(name, amount, category)
    @storage.add_expense(name, amount, category)
    session[:message] = "=> Expense added successfully."
    redirect "/"
  else
    session[:message] = "=> Invalid input. Try again."
    status 422
    @categories = all_categories
    erb :new
  end
end

# add a new category
post "/new/category" do
  new_category = params[:category]

  if valid_string?(new_category)
    @storage.add_category(new_category.capitalize)
    session[:message] = "=> Category added successfully."
    redirect "/new"
  else
    session[:message] = "=> Category name cannot be empty."
    erb :new
  end
end

# delete an expense
post "/delete/:id" do
  id = params[:id].to_i

  @storage.delete_expense(id)
  session[:message] = "=> Item deleted successfully."
  redirect "/"
end

get "/change_limit" do
  erb :change_limit
end

post "/change_limit" do
  new_limit = params[:new_limit]
  
  if valid_dollar_amount?(new_limit)
    @storage.limit = new_limit.to_f
    session[:message] = "=> Limit changed successfully."
    redirect "/"
  else
    session[:message] = "=> Invalid input. Try again."
    erb :change_limit
  end
end

after do
  @storage.disconnect
end
