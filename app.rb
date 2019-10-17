require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'bcrypt'
require 'carrierwave'

enable :sessions

configure do
  ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(Sinatra::Application.environment)
end

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 50 }  
  validates :email, presence: true, length: { maximum: 255 }, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }, uniqueness: { case_sensitive: false }
  has_secure_password
end
class PhotoUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  # #ファイル名変更
  # def filename
  #      "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  # end

  # protected
  # def secure_token(length=16)
  #     var = :"@#{mounted_as}_secure_token"
  #     model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  # end
end
class Post < ActiveRecord::Base
  extend CarrierWave::Mount
  mount_uploader :file,PhotoUploader
end

#users #signup
get '/users/sign_up' do
  @title = "sign_up"
  session[:user_id] ||= nil
  if session[:user_id]
    redirect '/home'
  end

  erb :'users/sign_up.html'
end

#users #signup #post
post '/users/sign_up' do
  user_params = {name: params[:name], email: params[:email], password: params[:password]}
  user = User.new(user_params)
  if user.save!
    session[:user_id] = user.id
    redirect '/users/welcome/'
  else
    redirect '/users/sign_up'
  end
end

#users #login
get '/users/log_in' do
  @title = "log_in"
  if session[:user_id]
    redirect '/home'
  end
  erb :'users/log_in.html'
end

#users #login #post
post '/users/log_in' do
  user = User.find_by(email: params[:email])
  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect '/home'
  else
    redirect "/users/log_in"
  end
end

#users #welcome
get '/users/welcome/' do 
  @title = "welcome"
    erb :'users/welcome.html'
end

#log_out
get '/log_out' do  

  if session[:user_id] != nil  
    session.clear  
    redirect to '/log_in'  
  else  
    redirect to '/'  
  end  
end

#root #index
get '/' do
  erb :'root/index.html'
end

#root #home
get '/home' do
  erb :'root/home.html'
end

#posts #index
get '/posts' do
  @posts = Post.all.reverse_order
  erb :'posts/index.html'
end

#posts #new
get '/posts/new' do
  erb :'posts/new.html'
end

#images #new #upload
post '/upload' do
  post = Post.new(file: params[:photo], post_text: params[:comment])
  if post.save!
    redirect '/posts'
  else
    redirect '/posts/new'
  end
end

#posts #show
get '/posts/:id' do
  @post = Post.find_by(id: params[:id])
  if @post.nil?
      "Not found..."
  else
      @title = "images"
      erb :'posts/show.html'
  end
end

#posts #edit
get '/posts/:id/edit' do
  @post = Post.find(params[:id])
  erb :'posts/edit.html'
end

#posts #update
put '/posts/:id' do
  post_params = { file: params[:photo], post_text: params[:comment] }
  post = Post.find(params[:id])
  if post.update!(post_params)
    redirect '/posts'
  else
    redirect "/posts/#{params[:id]}/edit"
  end
end

#posts #delete
delete '/posts/:id' do
  post = Post.find(params[:id])
  post.destroy!
  redirect '/posts'
end

configure do
  set :server, :puma
end