require "sinatra/base"
require "sinatra/activerecord"
require "json"

require_relative "application"

class Api < Sinatra::Application
  set :database, {
    adapter: 'postgresql',
    encoding: 'unicode',
    database: 'final_task_app',
    pool: 2,
    username: 'postgres',
    password: '34521'
  }

  get '/api/list_users' do
    content_type :json
    users_data = User.all.to_json
  end

  post '/api/create_user' do
    new_user = request.body.read
    user     = User.create(JSON.parse(new_user))
  end

  run! if app_file == $0
end
