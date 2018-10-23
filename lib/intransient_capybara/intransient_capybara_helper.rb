module IntransientCapybaraHelper

  def wait_for_response!(max_ajax_seconds = 3)
    wait_for_page_load!
    wait_for_ajax!(max_ajax_seconds)
  end

  def wait_for_ajax!(max_seconds = 3)
    active_ajax_count = nil

    begin
      wait_for('ajax requests', max_wait_time: max_seconds, polling_interval: 0.1) do
        page.document.synchronize do
          (page.evaluate_script 'typeof($) != "undefined"') && (active_ajax_count = page.evaluate_script("$.active")).zero?
          Rails.logger.info "#{active_ajax_count} outstanding XHR(s)"
        end
      end
    rescue StandardError
      assert(false, "waited #{max_seconds} seconds for ajax complete but #{active_ajax_count} ajax calls still active")
    end

    true
  end

  def wait_for_page_load!
    page.document.synchronize do
      current_path
      true
    end
  end

  def teardown_wait_for_requests_complete!
    stop_client
    block_rack_requests!

    wait_for('pending AJAX requests complete') do
      if ENV.fetch('TRACE_TEST_FRAMEWORK', false) == 'true'
        puts 'I am waiting for rack requests to clear out...'
      end
      RackRequestBlocker.num_active_requests == 0
    end
  end

  def block_rack_requests!
    if ENV.fetch('TRACE_TEST_FRAMEWORK', false) == 'true'
      puts 'I am turning off rack requests'
    end

    RackRequestBlocker.block_requests!
  end

  def allow_rack_requests!
    if ENV.fetch('TRACE_TEST_FRAMEWORK', false) == 'true'
      puts 'I am turning on rack requests'
    end

    RackRequestBlocker.allow_requests!
  end

  def wait_for(condition_name, max_wait_time: 30, polling_interval: 0.5)
    wait_until = Time.now + max_wait_time.seconds
    while true
      return if yield
      if Time.now > wait_until
        raise "Condition not met: #{condition_name}"
      else
        sleep(polling_interval)
      end
    end
  end

  def stop_client
    page.execute_script %Q{
      window.location = "about:blank";
    }
  end

  def report_traffic
    if ENV.fetch('DEBUG_TEST_TRAFFIC', false) == 'true'
      puts "Downloaded #{page.driver.network_traffic.map(&:response_parts).flatten.map(&:body_size).compact.sum / 1.megabyte} megabytes"
      puts "Processed #{page.driver.network_traffic.size} network requests"

      grouped_urls = page.driver.network_traffic.map(&:url).group_by{|url| /\Ahttps?:\/\/(?:.*\.)?(?:localhost|127\.0\.0\.1)/.match(url).present?}
      internal_urls = grouped_urls[true]
      external_urls = grouped_urls[false]

      if internal_urls.present?
        puts "Local URLs queried: #{internal_urls}"
      end

      if external_urls.present?
        puts "External URLs queried: #{external_urls}"

        if ENV.fetch('DEBUG_TEST_TRAFFIC_RAISE_EXTERNAL', false) == 'true'
          raise "Queried external URLs!  This will be slow! #{external_urls}"
        end
      end
    end
  end

  def resize_window_by(size)
    page.driver.browser.manage.window.resize_to size[0], size[1]
  end

end
