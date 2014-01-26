class Divider
  def initialize(app)
    @app = app
  end

  def call(env)
    env["QUERY_STRING"] = (env["QUERY_STRING"].to_i / 4).to_s
    env["PROCESSED_BY"] << "-Divider"
    @app.call(env)
  end
end