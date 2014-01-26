class Router
  def initialize(app)
    @app = app
  end

  def call(env)
    case env['REQUEST_PATH']
    when '/'
      [ 200,
        {"Content-Type" => "text/plain"},
        ["Hello from Rack!"]
      ]
    when '/car'
      [ 200,
        {"Content-Type" => "text/plain"},
        ["This is a car"]
      ]
    when '/plane'
      [ 200,
        {"Content-Type" => "text/plain"},
        ["This is a plane!"]
      ]
    else
      [404,
       {"Content-Type" => "text/plain"},
       ["Bad request"]
      ]
    end
  end
end