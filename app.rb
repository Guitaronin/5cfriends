require 'rubygems'
require 'sinatra'
require 'erb'
require 'logger'
require 'rack-flash'

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash
  
  ENV['RACK_ENV'] = File.open('local_config/env.config').read
  
  USERS = {
    :arian   => ['arian', 'R0ckstar!'],
    :susan   => ['susan', 'soozyQ101'],
    :kathryn => ['kathryn', 'thatswhatshesaid']
  }
  
  configure do
    $deployment = File.open('local_config/env.config').read.to_sym
    set :environment, $deployment
  end

  configure :development, :test do
  end

  configure :production do
  end
  
  before do
  end
  
  before %r{/.+} do
    set_user! unless logged_in?
    protected!
  end
  
  get '/logout' do
    unset_user!
    redirect '/'
  end
  
  get '/login' do
    redirect '/home'
  end
  
  get '/' do
    erb :index
  end
  
  get '/home' do
    erb :home
  end
  
  
  helpers do
    def protected!
      unless logged_in?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end
    
    def set_user!
      auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if auth.provided? && auth.basic? && auth.credentials
        session[:user] = USERS.invert[auth.credentials]
      end
    end
    
    def unset_user!
      session.delete(:user)
    end
    
    def user
      session[:user] ? session[:user].to_s.capitalize : nil
    end
    
    def logged_in?
      session[:user] ? true : false
    end
    
    def partial(template, locals = {})
      erb(template, :layout => false, :locals => locals, :cache => false)
    end
  end
  
end