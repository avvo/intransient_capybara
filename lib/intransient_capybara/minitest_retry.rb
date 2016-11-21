# Adapted from https://github.com/appfolio/minitest-optional_retry/blob/master/lib/minitest/optional_retry.rb
require 'minitest/autorun'
require 'atomic'

module Minitest
  module OptionalRetry

    GLOBAL_RETRY_LIMIT = 25
    @@global_retry_count = Atomic.new(0)

    def run_one_method(klass, method_name, reporter)
      first_result = nil
      report_result = nil

      retries = [ENV.fetch('MINITEST_RETRY_COUNT', 3).to_i, 1].max

      retries.times do
        result = Minitest.run_one_method(klass, method_name)

        first_result ||= result

        if result.passed?
          report_result = result
          break
        else
          if @@global_retry_count.value >= GLOBAL_RETRY_LIMIT
            puts 'We hit the global retry limit, you probably have a more global issue going on.  We will not try to rerun transients anymore.'
            break
          end

          if result.failure.exception.present? && result.failure.exception.class.to_s == 'Capybara::Poltergeist::DeadClient'
            puts "PhantomJS died!!!! - #{klass.to_s}##{method_name}"
            next
          end

          puts "Test failed!!!! - #{klass.to_s}##{method_name}"

          @@global_retry_count.update { |v| v + 1 }
        end

      end

      report_result ||= first_result

      if !first_result.passed? && report_result.passed?
        puts "#{klass.to_s}##{method_name} IS TRANSIENT!!!!! IT FAILED THE FIRST TRY THEN PASSED IN RETRIES"
      end

      reporter.record(report_result)
    end
  end
end
