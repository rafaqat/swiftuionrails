# frozen_string_literal: true

class DisableCspForPlayground
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Remove CSP headers for playground routes
    if env["PATH_INFO"] =~ /^\/playground/
      headers.delete("Content-Security-Policy")
      headers.delete("Content-Security-Policy-Report-Only")
    end

    [ status, headers, response ]
  end
end
