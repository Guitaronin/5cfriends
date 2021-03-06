require 'rubygems'
require 'sinatra'
require 'erb'
require 'logger'
require 'rack-flash'
require 'mongomatic'
require 'cgi'
require 'mechanize'

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
  
  get '/smartypants' do
    if params[:url]
      # url = 'http://' + CGI.unescape(params[:url])
      return Mechanize.new.get(params[:url]).body
    else
      erb :smartypants, :layout => false
    end
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
    @postits = Postit.find.sort(:created_at, :desc).to_a
    erb :home
  end
  
  
  
  post '/postit' do
    postit_doc = {
      :user    => user,
      :message => params[:message]
    }
    
    Postit.insert(postit_doc)
    redirect '/home'
  end
  
##################################
# CHORES                         #
##################################
  
  get '/chores' do
    @chores = Chore.find.to_a
    erb :chores
  end
  
  get '/chore/new' do
    erb :chore_new
  end
  
  get '/chore/:id' do
    @chore = Chore.find_one( :_id => BSON::ObjectId(params[:id]) )
    erb :chore
  end
  
  get '/chore/edit/:id' do
    @chore = Chore.find_one( :_id => BSON::ObjectId(params[:id]) )
    erb :chore_edit
  end
  
  post '/chore/create' do
    chore_doc = {
      :name        => params[:name],
      :description => params[:description]
    }
    
    chore_id = Chore.insert(chore_doc)
    redirect "/chore/#{chore_id}"
  end
  
  post '/chore/update' do
    chore = Chore.find_one( :_id => BSON::ObjectId(params[:id]) )

    chore['name']        = params[:name]
    chore['description'] = params[:description]
    
    chore.update
    redirect '/chores'
  end
  
  post '/chore/delete' do
    chore = Chore.find_one( :_id => BSON::ObjectId(params[:id]) )
    chore.remove
    redirect '/chores'
  end
  
  ##################################
  # BILLS                          #
  ##################################

    get '/bills' do
      @bills = Bill.find.to_a
      erb :bills
    end

    get '/bill/new' do
      erb :bill_new
    end

    get '/bill/:id' do
      @bill = Bill.find_one( :_id => BSON::ObjectId(params[:id]) )
      erb :bill
    end

    get '/bill/edit/:id' do
      @bill = Bill.find_one( :_id => BSON::ObjectId(params[:id]) )
      erb :bill_edit
    end

    post '/bill/create' do
      bill_doc = {
        :name        => params[:name],
        :amount      => params[:amount],
        :due_date    => params[:due_date],
        :description => params[:description]
      }

      bill_id = Bill.insert(bill_doc)
      redirect "/bill/#{bill_id}"
    end

    post '/bill/update' do
      bill = Bill.find_one( :_id => BSON::ObjectId(params[:id]) )

      bill['name']        = params[:name]
      bill['amount']      = params[:amount]
      bill['due_date']    = params[:due_date]
      bill['description'] = params[:description]

      bill.update
      redirect '/bills'
    end

    post '/bill/delete' do
      bill = Bill.find_one( :_id => BSON::ObjectId(params[:id]) )
      bill.remove
      redirect '/bills'
    end
    
    
    ##################################
    # MESSAGES                          #
    ##################################

      get '/messages' do
        @messages = Message.find.to_a
        erb :messages
      end

      get '/message/new' do
        erb :message_new
      end

      get '/message/:id' do
        @message = Message.find_one( :_id => BSON::ObjectId(params[:id]) )
        erb :message
      end

      # get '/message/edit/:id' do
      #   @message = Message.find_one( :_id => BSON::ObjectId(params[:id]) )
      #   erb :message_edit
      # end

      post '/message/create' do
        message_doc = {
          :author        => user,
          :message       => params[:message],
          :created_stamp => Time.now
        }
        
        if params[:thread_id]
          thread_id = params[:thread_id]
          thread_doc = Message.find_one(:_id => thread_id)
          thread_doc['messages'] << message_doc
          thread_doc.update
        else
          thread_doc = {
            :subject  => params[:subject],
            # :readers  => params[:readers],
            :messages => [message_doc]
          }
          thread_id = Message.insert(thread_doc)
        end

        redirect "/message/#{thread_id}"
      end

      # post '/message/update' do
      #   message = Message.find_one( :_id => BSON::ObjectId(params[:id]) )
      # 
      #   message['name']        = params[:name]
      #   message['amount']      = params[:amount]
      #   message['due_date']    = params[:due_date]
      #   message['description'] = params[:description]
      # 
      #   message.update
      #   redirect '/messages'
      # end

      post '/message/delete' do
        message = Message.find_one( :_id => BSON::ObjectId(params[:id]) )
        message.remove
        redirect '/messages'
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
    
    def find(query={}, opts={})
      results = super(query, opts)
      results ? results : {}
    end

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

class Postit < Model
  created_stamp true
  updated_stamp true
end

class Chore < Model
  created_stamp true
  updated_stamp true
end

class Bill < Model
  created_stamp true
  updated_stamp true
end

class User < Model
  created_stamp true
  updated_stamp true
end