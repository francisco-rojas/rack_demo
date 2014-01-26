class Multiplier
  def initialize(app)
    @app = app
  end

  def call(env)
    # Process Request
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i * env["QUERY_STRING"].to_i).to_s
    env["PROCESSED_BY"] = "Multiplier"
    # Pass control to next middleware or app
    resp = @app.call(env)
    # Process Response
    resp[2] << "-Back to Multiplier"
    resp
  end
end