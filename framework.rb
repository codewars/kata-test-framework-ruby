
$describing = false

class Test

  class Error < StandardError
  end

  @@html = []
  @@method_calls = {}
  @@failed = []
  @@before_blocks = []
  @@after_blocks = []

  class << self

    def log(message, no_line_break = false)
      if $describing
        message = message.to_s
        @@html << message
        @@html << '<br>' unless no_line_break

      else
        puts message.to_s
      end
      nil
    end

    def expect(passed = nil, message = nil, options = {}, &block)
      log_call(:expect)

      if block_given? ? block.call() : !!passed
        success_msg = "Test Passed"
        success_msg += ": " + options[:success_msg] if options[:success_msg]

        log '<div class="console-passed">' + success_msg + '</div>', true
      else
        message ||= "Something is wrong"
        log "<div class='console-failed'>Test Failed: " + message.to_s + "</div>", true

        if $describing
          @@failed << Test::Error.new(message)
        else
          raise Test::Error, (message)
        end
      end

    end

    def describe(message)
      log_call(:describe)
      begin
        $describing = true
        @@html << '<div class="console-describe"><h6>'
        @@html << message
        @@html << ':</h6>'
        yield
      ensure
        $describing = false
        @@html << '</div>'
        puts @@html.join
        @@html.clear
        @@before_blocks.clear
        @@after_blocks.clear

        raise @@failed.first if @@failed.any?
      end
    end

    def it(message)
      log_call(:it)
      begin
        @@html << '<div class="console-it"><h6>'
        @@html << message
        @@html << ':</h6>'
        @@before_blocks.each do |block|
          block.call
        end
        begin
          yield
        ensure
          @@after_blocks.each do |block|
            block.call
          end
        end
      ensure
        @@html << '</div>'
      end
    end

    def before(&block)
      @@before_blocks << block
    end

    def after(&block)
      @@after_blocks << block
    end

    def expect_tests_to_pass(message, &block)
      log_call(:expect_tests_to_pass)

      begin
        block.call
      rescue Test::Error => ex
        Test.expect(false, 'Expected test cases to pass: ' + ((message and message.to_s)|| ex.message))
      end
    end

    def expect_tests_to_fail(message, &block)
      log_call(:expect_tests_to_fail)

      passed = false
      begin
        block.call
      rescue Test::Error => ex
        passed = true
      end

      Test.expect(passed, message || 'Expected tests to fail')
    end

    def expect_error(message = nil, &block)
      log_call(:expect_error)

      passed = false
      begin
        block.call
      rescue
        passed = true
      end

      Test.expect(passed, message || 'Expected an error to be raised')
    end

    def expect_no_error(message = nil, &block)
      log_call(:expect_no_error)
      begin
        block.call
        Test.expect(true)
      rescue Test::Error => test_ex
      rescue => ex
        message ||= 'Unexpected error was raised.'
        Test.expect(false, message + ": " + ex.message)
      end
    end

    def assert_equals(actual, expected, msg = nil, options = {})
      log_call(:assert_equals)
      if actual != expected
        msg = msg ? msg + ' -  ' : ''
        message = "\#{msg}\Expected: " + expected.inspect + ", instead got: " + actual.inspect
        Test.expect(false, message)
      else
        options[:success_msg] ||= 'Value == ' + expected.inspect
        Test.expect(true, nil, options)
      end
    end

    def assert_not_equals(actual, expected, msg = nil, options = {})
      log_call(:assert_not_equals)
      if actual == expected
        msg = msg ? msg + ' - ' : ''
        message = "\#{msg}\Not expected: " + actual.inspect
        Test.expect(false, message)
      else
        options[:success_msg] ||= 'Value != ' + expected.inspect
        Test.expect(true, nil, options)
      end
    end

    def random_letter
      log_call(:random_letter)
      ('a'..'z').to_a.sample
    end

    def random_token
      log_call(:random_token)
      rand(36**6).to_s(36)
    end

    def random_number
      log_call(:random_number)
      rand(100)
    end

    def call_count(name)
      @@method_calls[name.to_sym] ||= 0
    end

    private

    def log_call(name)
      call_count(name)
      @@method_calls[name] += 1
    end

  end
end

def describe(message, &block)
  Test.describe(message, &block)
end

def it(message, &block)
  Test.it(message, &block)
end

def before(&block)
  Test.before(&block)
end

def after(&block)
  Test.after(&block)
end