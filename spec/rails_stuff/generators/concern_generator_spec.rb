# Here is Minitest test from Rails, I've made it when proposed this generator
# to rails.
#
# While there is no built-in support for generator specs in RSpec,
# it just create exaples which run Minitest tests.

require 'rails_stuff/generators/concern/concern_generator'

class ConcernGeneratorTest < Rails::Generators::TestCase
  self.generator_class = RailsStuff::Generators::ConcernGenerator
  arguments %w[User::Authentication]

  def test_concern_is_created
    run_generator
    assert_file 'app/models/user/authentication.rb' do |content|
      assert_match(/module User::Authentication/, content)
      assert_match(/extend ActiveSupport::Concern/, content)
      assert_match(/included do/, content)
    end
  end

  def test_concern_on_revoke
    concern_path = 'app/models/user/authentication.rb'
    run_generator
    assert_file concern_path
    run_generator ['User::Authentication'], behavior: :revoke
    assert_no_file concern_path
  end
end

class ControllerConcernGeneratorTest < Rails::Generators::TestCase
  self.generator_class = RailsStuff::Generators::ConcernGenerator
  arguments %w[admin_controller/localized]

  def test_concern_is_created
    run_generator
    assert_file 'app/controllers/admin_controller/localized.rb' do |content|
      assert_match(/module AdminController::Localized/, content)
      assert_match(/extend ActiveSupport::Concern/, content)
      assert_match(/included do/, content)
    end
  end
end

Rails::Generators::TestCase.destination File.expand_path('tmp', GEM_ROOT)

RSpec.describe RailsStuff::Generators::ConcernGenerator do
  [ConcernGeneratorTest, ControllerConcernGeneratorTest].each do |klass|
    klass.test_order = :random
    klass.runnable_methods.each do |method_name|
      it "[delegation to #{klass.name}##{method_name}]" do
        test = klass.new(method_name)
        test.run
        test.failures.first.try! { |x| raise x }
      end
    end
  end
end
