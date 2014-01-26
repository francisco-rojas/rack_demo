class RackApp
  def self.call(env)
    env["PROCESSED_BY"] << "-RackApp"
    [ 200,
      {"Content-Type" => "text/plain"},
      [env["QUERY_STRING"] + "\n", env["PROCESSED_BY"]]
    ]
  end
end