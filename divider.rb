class Divider
  def initialize(app)
    @app = app
  end

  def call(env)
    # Process Request
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i / 4).to_s
    env["PROCESSED_BY"] << "-Divider"
    # Pass control to next middleware or app
    resp = @app.call(env)
    # Process Response
    resp[2] << "-Back to Divider"
    resp
  end
end