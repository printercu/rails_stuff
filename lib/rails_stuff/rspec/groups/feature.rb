module RailsStuff
  module RSpec
    module Groups
      module Feature
        def wait_for_ajax
          Timeout.timeout(Capybara.default_max_wait_time) do
            loop until finished_all_ajax_requests?
          end
        end

        # Tuned for jQuery, override it if you don't use jQuery.
        def finished_all_ajax_requests?
          page.evaluate_script('jQuery.active').zero?
        end

        def pause
          $stderr.write 'Press enter to continue'
          $stdin.gets
        end

        ::RSpec.configuration.include self, type: :feature
      end
    end
  end
end
