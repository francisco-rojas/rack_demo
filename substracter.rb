class Substracter
  def initialize(app)
    @app = app
  end

  def call(env)
    # Process Request
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i - env["QUERY_STRING"].to_i / 2).to_s
    env["PROCESSED_BY"] << "-Substracter"
    # Pass control to next middleware or app
    resp = @app.call(env)
    # Process Response
    resp[2] << "-Back to Substracter"
    resp
  end
end