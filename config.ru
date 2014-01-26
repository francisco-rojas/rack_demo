require 'rack'
require './rack_app'
require './router'

# If you happen to instantiate a Rack object inside config.ru, it will be reused as long as Rack application runs.
# It means that the content of instance variables will be carried between requests if not set otherwise.
# It is a better idea to always define #call as a class method, i.e. pass in the class instead of an object inside
# rackup configuration file.

# Runs a rack application in which the #call method is an instance method
# run RackApp.new

# Adds a middleware to the stack
use Router
# Runs a rack application in which the #call method is a class method
run RackApp

