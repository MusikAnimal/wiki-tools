require 'sinatra'
require 'haml'
require 'sass/plugin/rack'
require 'mysql2'
require './app'
require './repl'
require './auth'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

run Sinatra::Application
