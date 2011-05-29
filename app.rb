require 'rubygems'
require 'sinatra'
require 'erb'
require 'logger'
require 'rack-flash'
require 'mongomatic'

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
    erb :index, :layout => false
  end
  
  get '/home' do
    @messages = Message.find.sort(:timestamp, :desc).to_a
    erb :home
  end
  
  post '/message' do
    message_doc = {
      :user    => user,
      :message => params[:message]
    }
    
    Message.insert(message_doc)
    redirect '/home'
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



class Model < Mongomatic::Base
  Mongomatic.db = Mongo::Connection.new.db('5cfriends')
  
  class << self
    @@opts = {}

    def insert(doc_hash, opts={})
      if @@opts[:created_stamp] == true
        doc_hash.merge!(:created_at => Time.now)
      end
      super(doc_hash, opts)
    end

    def update(opts={},update_doc=@doc)
      if @@opts[:updated_stamp] == true
        update_doc.merge!(:updated_at => Time.now)
      end
      super(opts, update_doc)
    end

    def created_stamp(bool)
      @@opts[:created_stamp] = bool
    end

    def updated_stamp(bool)
      @@opts[:created_stamp] = bool
    end

  end
end

class Message < Model
  created_stamp true
  updated_stamp true
end