require 'rubygems'
require 'sinatra'
require 'erb'
require 'logger'
require 'rack-flash'

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash
  
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
  
  get '/' do
    erb :index
  end
end