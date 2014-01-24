Rack Demo
=========
This is a demonstration of how Rack works. Specifically, what is a Rack Application, and what is Rack Middleware.

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

`
*Request by the browser*

GET /users HTTP/1.1
Host: localhost
Connection: close

*Server to Rack app*

env = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/users',
  'HTTP_VERSION' => '1.1',
  'HTTP_HOST' => 'localhost',
  ...
  ...
}
`
The *env* variable is sent to the app. The app does all its work based on the information
it got from this variable and returns a response to the server. This response is made
exactly how Rack specified, so that the server can understand it.

The app
-------
What the app gives back to the server is a simple Array. This array has exactly 3 elements
in it. First is the HTTP status code of the response, second is a Hash of HTTP headers
and the third element is a body object (which must respond to each).

`
// Rails app to server

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
`
The server can finally take this array and convert it into a valid HTTP response and
send it to the browser (client).

So ‘Rack’ is basically specification of these two things: what the server should send
to the app and what the app should return to the server. That’s it.

Now there are certain rules about what things the Ruby app should compose of, to be able
to work with that *env* variable from the server. In its most basic sense this is what the
Rack app should contain:

`
class App
  def call(env)
    [
      200,
      { 'Content-Length' => 25, 'Content-Type' => 'text/html' },
      [ "<html>", "...", "</html>" ]
    ]
  end
end
`

The app should implement a method named *call* which accepts a parameter *env*. And this method
should return the resultant Array. Any app that confirms to this rule is a Rack application.

Rack Application vs. Rack Middleware
------------------------------------
Rack is a common Ruby web infrastructure. Rack Middleware is a way to implement a pipelined
development process for web applications. Both respond to *#call(env)*. But unlike Rack
applications, Rack middleware has knowledge of other Rack applications.

The simplest Rack application (in class instead of lambda form) would be something like this:

`
class RackApp
  def call(env)
    [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]
  end
end
`
Note that because the method required by the Rack specification is *call* and (by no coincidence)
this is how you execute Procs and lambdas in Ruby, the same thing can be written like so:

`
lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
`

This hello world app would simply output “Hello world!” from any URL on the server that was running it.
But what if we want to filter the request? What if we want to add some headers before the main
application gets it, or perhaps translate the response into pig latin after the fact?
We have no way to say “before this” or “after that” in a Rack application. This is where middleware comes
into place:

`
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
`

A Rack middleware has an initializer that takes a Rack application as parameter. This way, it can perform
actions before, after, or around the Rack application because it has access to it during the call-time.
That’s why this works in a config.ru file:

`
run lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
`

But this does not:

`
use lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}
`

Because the ‘use’ keyword indicates a Middleware that should be instantiated at call-time with the arguments
provided and then called, while ‘run’ simply calls an already existing instance of a Rack application.

References
----------
http://rack.rubyforge.org/doc/
http://www.intridea.com/blog/2010/4/20/rack-middleware-and-applications-whats-the-difference
http://gauravchande.com/what-is-rack-in-ruby-rails
http://www.cise.ufl.edu/research/ParallelPatterns/PatternLanguage/AlgorithmStructure/Pipeline.htm
http://railscasts.com/episodes/151-rack-middleware?view=asciicast

