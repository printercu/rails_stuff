RSpec::Matchers.define :be_valid_js do
  match_unless_raises do |actual|
    ExecJS.exec("var test = function(){\n#{actual}\n}")
  end

  failure_message do |actual|
    js_error = rescued_exception.message
    line = js_error.lines[0].split(':').last.to_i - 1
    js_error = /SyntaxError.*$/.match(js_error)[0] if js_error.include?('SyntaxError')
    "expected string to be valid js, got '#{js_error}' on line #{line} for\n\n#{actual}"
  end
end
