class Substracter
  def initialize(app)
    @app = app
  end

  def call(env)
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i - env["QUERY_STRING"].to_i / 2).to_s
    env["PROCESSED_BY"] << "-Substracter"
    @app.call(env)
  end
end