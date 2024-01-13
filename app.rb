require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

require_relative 'expense_class'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

def display_limit_message
  if session[:expenses].exceeded_limit?
    session[:limit_message] = "You have exceeded your limit."
  end
end

get "/" do
  unless session[:expenses]
    session[:expenses] = Expenses.new

    # test data
    session[:expenses].new_expense('Family Dinner', 134.99, 1)
    session[:expenses].new_expense('Winter Tires', 549.99, 3)
    session[:expenses].new_expense('S&P 500', 200.00, 4)

    session[:categories] = session[:expenses].categories
  end
  
  session[:limit] = session[:expenses].limit
  session[:total_spent] = session[:expenses].total_list_amount
  display_limit_message

  erb :main
end

def valid_expense_input?(name, amount, category)
  (name.strip.size > 0) &&
  (amount.match?(/\A\d+(\.\d+)?\z/)) &&
  (1..session[:categories].size).include?(category.to_i)
end

get "/new" do
  erb :new
end

post "/new/expense" do
  name = params[:name]
  amount = params[:amount]
  category = params[:category]

  if valid_expense_input?(name, amount, category)
    session[:expenses].new_expense(name, amount, category)
    session[:message] = "=> Expense added successfully."
    redirect "/"
  else
    session[:message] = "=> Invalid input. Try again."
    status 422
    erb :new
  end
end

post "/new/category" do
  new_category = params[:category]

  if !(new_category.strip.size > 0)
    session[:message] = "=> Category name cannot be empty."
    erb :new
  else
    session[:expenses].new_category(params[:category].capitalize)
    session[:categories] = session[:expenses].categories
    session[:message] = "=> Category added successfully."
    redirect "/new"
  end
end

post "/delete/:id" do
  id = params[:id].to_i

  session[:expenses].delete_expense(id)
  session[:message] = "=> Item deleted successfully."
  redirect "/"
end

get "/change_limit" do
  erb :change_limit
end

post "/change_limit" do
  new_limit = params[:new_limit]
  
  if new_limit.match?(/\A\d+(\.\d+)?\z/)
    session[:message] = "=> Limit changed successfully."
    session[:expenses].limit = new_limit.to_f
    redirect "/"
  else
    session[:message] = "=> Invalid input. Try again."
    erb :change_limit
  end
end
