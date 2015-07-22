require 'rspec'
require 'opencode_theme'
require 'opencode_theme/cli'

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

require 'logger'
require 'http_logger'

File.truncate('http.log', 0) if File.exists? 'http.log'
HttpLogger.logger = Logger.new 'http.log'
HttpLogger.colorize = false
HttpLogger.log_headers = true
HttpLogger.log_request_body  = true
HttpLogger.log_response_body = true
HttpLogger.level = :info
