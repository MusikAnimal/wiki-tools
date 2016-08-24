require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass/plugin/rack'
require 'mysql2'

`stat app.rb`
`stat repl.rb`
`stat auth.rb`

require './app'
require './repl'
require './auth'

root = ::File.dirname(__FILE__)
require ::File.join(root, 'app')
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

run WikiTools.new
