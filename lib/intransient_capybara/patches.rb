module Capybara
  module Node
    class Base
      def synchronize(seconds=Capybara.default_max_wait_time, options = {})
        start_time = Capybara::Helpers.monotonic_time

        begin
          if session.synchronized
            yield
          else
            session.synchronized = true
            begin
              yield
            rescue => e
              session.raise_server_error!
              raise e unless driver.wait?
              raise e unless catch_error?(e, options[:errors])
              if (Capybara::Helpers.monotonic_time - start_time) >= seconds

                ### This is a patched part
                warn "Capybara's timeout limit reached - if your tests are green, something is wrong"
                ###

                raise e
              end
              sleep(0.05)
              raise Capybara::FrozenInTime, "time appears to be frozen, Capybara does not work with libraries which freeze time, consider using time travelling instead" if Capybara::Helpers.monotonic_time == start_time
              reload if Capybara.automatic_reload
              retry
            ensure
              session.synchronized = false
            end
          end
        rescue Capybara::ElementNotFound => sad_day
          ### This is a patched part

          puts 'We failed to find an element :('
          puts
          puts 'We are on path: ' + session.current_path
          puts
          puts 'This is the page HTML: ' + session.body
          puts
          raise sad_day

          ###
        end

      end
    end
  end

  class Session
    def raise_server_error!
      if Capybara.raise_server_errors and @server and @server.error
        raise @server.error
      end
    ensure
      @server.reset_error! if @server
    end
  end
end
