Rack Demo
=========
This is a demonstration of how Rack works. Specifically, what is a Rack Application, and what is Rack Middleware.


Introduction
------------
Rack provides an interface for developing web applications in Ruby.
By wrapping HTTP requests and responses in the simplest way possible, it unifies
and distills the API for web servers, web frameworks, and software in between
(the so-called middleware) into a single method call.

*IN OTHER WORDS:* RACK is an intermediary between a web server, such as WEBbrick,
and a Rack application, such as a Rails application.
It specifies the format in which web servers should pass HTTP requests to
Rack applications, and the format in which Rack applications should pass response
objects to web servers.

The server
----------
The server, according to Rack´s specification, will convert the HTTP request to a simple Ruby Hash, as shown below:

```Ruby
# Request by the browser

GET /users HTTP/1.1
Host: localhost
Connection: close

# Server to Rack app

env = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/users',
  'HTTP_VERSION' => '1.1',
  'HTTP_HOST' => 'localhost',
  ...
  ...
}
```

The *env* variable is sent to the app. The app does all its work based on the information
it got from this variable and returns a response to the server. This response is made
exactly how Rack specified, so that the server can understand it.

The Rack application
--------------------
What the app gives back to the server is a simple Array. This array has exactly 3 elements
in it. First is the HTTP status code of the response, second is a Hash of HTTP headers
and the third element is a body object *(which must respond to each)*.

```Ruby
# Rails app to server

[
  200,
  {
    'Content-Length' => '25',
    'Content-Type' => 'text/html'
  },
  [
    '<html>',
    '...',
    '</html>'
  ]
]
```

The server can finally take this array and convert it into a valid HTTP response and
send it to the browser (client).

So 'Rack' is basically a specification of these two things: what the server should send
to the app and what the app should return to the server. That’s it.

Now there are certain rules about what things the Ruby app should compose of, to be able
to work with that *env* variable from the server. In its most basic sense this is what the
Rack app should contain:

```Ruby
class App
  def call(env)
    [
      200,
      { 'Content-Length' => 25, 'Content-Type' => 'text/html' },
      [ "<html>", "...", "</html>" ]
    ]
  end
end
```

The app should implement a method named *call* which accepts a parameter *env*. And this method
should return the resultant Array. Any app that confirms to this rule is a Rack application.

Class vs Object
---------------
If you happen to instantiate a Rack object inside config.ru, it will be reused as long as Rack application runs.
It means that the content of instance variables will be carried between requests if not set otherwise.
**It is a better idea to always define #call as a class method, i.e. pass in the class instead of an object inside
rackup configuration file.**

```Ruby
# Runs a rack application in which the 'call' method is an instance method
run RackApp.new

# Runs a rack application in which the 'call' method is a class method
run RackApp
```

Rack Application vs. Rack Middleware
------------------------------------
Rack is a common Ruby web infrastructure. Rack Middleware is a way to implement a pipelined
development process for web applications. Both respond to *#call(env)*. But unlike Rack
applications, Rack middleware has knowledge of other Rack applications or middlewares.

The simplest Rack application (in class instead of lambda form) would be something like this:

```Ruby
class RackApp
  def call(env)
    [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]
  end
end
```

Note that because the method required by the Rack specification is *call* and (by no coincidence)
this is how you execute Procs and lambdas in Ruby, the same thing can be written like so:

```Ruby
lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
```

This hello world app would simply output “Hello world!” from any URL on the server that was running it.
But what if we want to filter the request? What if we want to add some headers before the main
application gets it, or perhaps translate the response into pig latin after the fact?
We have no way to say “before this” or “after that” in a Rack application. This is where middleware comes
into place:

```Ruby
class RackMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Make the app always think the URL is /pwned
    env['PATH_INFO'] = '/pwned'
    @app.call(env)
  end
end
```

A Rack middleware has an initializer that takes a Rack application or middleware as parameter. This way,
it can perform actions before, after, or around the Rack application because it has access to it during
the call-time.

In other words we can wrap a simple Rack application with a middleware, and then again, we can wrap
the result with another middleware, and so on. As Rack middlewares have access to a passed in application,
they can perform actions before or after they are passed to another Rack application.

The 'use' keyword is used to define middlewares to instantiate, while by 'run' keyword designates a Rack application.

That’s why this works in a config.ru file:

```Ruby
run lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
```

But this does not:

```Ruby
use lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
```

Because the 'use' keyword indicates a Middleware that should be instantiated at call-time with the arguments
provided and then called, while 'run' simply calls an already existing instance of a Rack application.

For example, in a Rails app you can 'cd' into the app and run the command 'rake middleware' to see what middleware
Rails is using:

```Ruby
$ cd my-rails-app
$ rake middleware
use ActionDispatch::Static
use Rack::Lock
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007fcc4481ae08>
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use Rails::Rack::Logger
.
.
.
use ActionDispatch::BestStandardsSupport
run MyRailsApp::Application.routes
```

Every request that comes into this app starts at the top of this stack, bubbles its way down, hits the router
at the bottom, which dispatches to a controller that generates some kind of response (usually some HTML),
which then bubbles its way back up through the stack before being sent back to the browser.

```Ruby
use Middleware1
use Middleware2
use Middleware3
run MyApp

#=> Boils down to Middleware1.new(Middleware2.new(Middleware3.new(MyApp)))
```

Behind the scenes the code looks something lie this:

```Ruby
class ParamsParser
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new env
    env['params'] = request.params
    app.call env
  end
end

class HelloWorldApp
  def self.call(env)
    parser = ParamsParser.new self
    env = parser.call env
    # env['params'] is now set to a hash for all the input paramters

    [200, {}, env['params'].inspect]
  end
end
```

Middleware Stack
----------------
Rack::Builder helps creating a middleware stack. It wraps one Rack middleware around another and
then around a given Rack application. Each object is instantiated with the next one, following in
the stack as a parameter, creating a final Rack application.

```Ruby
app = Rack::Builder.new do
  use Rack::Etag		# Add an ETag
  use Rack::Deflator	# Compress
  run FancyRackApp		# User-defined logic
end
```

The code inside rackup configuration file is wrapped around with a Rack::Builder instance.

Cascading Rack Apps
-------------------
Rack::Cascade provides a way to combine Rack applications as a sequence. It takes an array of Rack applications
as an argument. When a new request arrives, it will try to use the first Rack app in the array, if it gets a 404
response it will move to the next one.

```Ruby
require "rack_app"
run Rack::Cascade.new([Rack::File.new("public"), FancyRackApp])
```

The first app in our array is Rack::File, which serves static files from the directory provided as an argument.
If there is a request for a file from public directory, Rack::File will try to look for it. If not found,
Rack::Cascade will move execution to next application from the list.

Abstracting Requests and Responses
----------------------------------
Rack::Request and Rack::Response provide convenient abstractions. The former class helps to handle incoming
information, wrapping *env* hash and the latter makes it easier to generate response triplets.
Remember to require 'rack'

```Ruby
# Using Rack::Request
def call(env)
  req = Rack::Request.new(env)
  req.request_method #=> GET, POST, PUT, etc.
  req.get?           # is this a GET requestion
  req.path_info      # the path this request came in on
  req.session        # access to the session object, if using the Rack::Session middleware
  req.params         # a hash of merged GET and POST params, useful for pulling values out of a query string
  req.params['foo']  # specific user-data
  req.params['baaz'] =  'something
  req.post?   # a POST request ?
  req.xhr?   # an AJAX request ?
  # ... and many more
end
```

**It is important to note that modifying Rack::Request instance also modifies underlying env hash.**

```Ruby
# Using Rack::Response

class Hello
  def self.call(env)
    res = Rack::Response.new
    res.write "Hello from Rack!"		# write some content to the body. This will automatically set the Content-Length header for you
    response.body = ['Hello World'] 	# or set it directly
    res["Content-Type"] = "text/plain"	# You can get/set headers with square bracket syntax
    res['X-Custom-Header'] = 'foo'
    res.set_cookie("user_id", 1) 		# You can set and delete cookies
    res.delete_cookie("user_id")
    res.status							# You can set the status code
    res.finish							# returns the standard [status, headers, body] array
  end
end
```

Reloading
---------
There is a handy Rack middleware which reloads the source of Rack application if it changed.

```Ruby
use Rack::Reloader, 0
run RackApp
```

The only problem is that it only reloads Ruby files. If you have dynamic templates, you can
take a look at rerun gem.

Authentication
--------------
Another useful middleware is Rack::Auth::Basic. It can be used to protect our applications
with Basic HTTP authentication.

```Ruby
use Rack::Auth::Basic, "Restricted Area" do |username, password|
  [username, password] == ['admin', 'admin']
end
```

Rack env hash contents
-----------------------

```Ruby
{
"SERVER_SOFTWARE"=>"thin 1.5.0 codename Knife",
"SERVER_NAME"=>"localhost",
"rack.input"=>#<Rack::Lint::InputWrapper:0x007ffdec490218 @input=#<StringIO:0x007ffdec4ccc18>>,
"rack.version"=>[1, 0],
"rack.errors"=>#<Rack::Lint::ErrorWrapper:0x007ffdec490128 @error=#<IO:<STDERR>>>,
"rack.multithread"=>false,
"rack.multiprocess"=>false,
"rack.run_once"=>false,
"REQUEST_METHOD"=>"GET",
"REQUEST_PATH"=>"/",
"PATH_INFO"=>"/",
"REQUEST_URI"=>"/",
"HTTP_VERSION"=>"HTTP/1.1",
"HTTP_USER_AGENT"=>"curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5",
"HTTP_HOST"=>"localhost:9292",
"HTTP_ACCEPT"=>"*/*",
"GATEWAY_INTERFACE"=>"CGI/1.2",
"SERVER_PORT"=>"9292",
"QUERY_STRING"=>"",
"SERVER_PROTOCOL"=>"HTTP/1.1",
"rack.url_scheme"=>"http",
"SCRIPT_NAME"=>"",
"REMOTE_ADDR"=>"127.0.0.1",
"async.callback"=>#<Method: Thin::Connection#post_process>,
"async.close"=>#<EventMachine::DefaultDeferrable:0x007ffdec496410>
}
```

References
----------
* http://rack.rubyforge.org/doc/
* http://www.intridea.com/blog/2010/4/20/rack-middleware-and-applications-whats-the-difference
* http://hawkins.io/2012/07/rack_from_the_beginning/
* http://zaiste.net/2012/08/concisely_about_rack_applications/
* http://net.tutsplus.com/tutorials/exploring-rack/
* http://gauravchande.com/what-is-rack-in-ruby-rails
* http://www.cise.ufl.edu/research/ParallelPatterns/PatternLanguage/AlgorithmStructure/Pipeline.htm
* http://railscasts.com/episodes/151-rack-middleware?view=asciicast

