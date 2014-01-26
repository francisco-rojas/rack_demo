class Multiplier
  def initialize(app)
    @app = app
  end

  def call(env)
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i * env["QUERY_STRING"].to_i).to_s
    env["PROCESSED_BY"] = "Multiplier"
    @app.call(env)
  end
end