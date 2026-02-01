# Rails 8 Application Template
# Authentication: Devise
# Authorization: Pundit (policy-based)
# CSS: Tailwind CSS
# Testing: Minitest with FactoryBot
#
# Usage:
#   rails new myapp -m /path/to/template.rb
#   rails new myapp -m https://raw.githubusercontent.com/gpaddis/rails-templates/main/template.rb

# =============================================================================
# Phase 1: Gems
# =============================================================================

gem "devise"
gem "pundit"
gem "tailwindcss-rails"

gem_group :development, :test do
  gem "factory_bot_rails"
end

# =============================================================================
# Phase 2-6: After Bundle Setup
# =============================================================================

after_bundle do
  # ===========================================================================
  # Phase 2: Devise Setup
  # ===========================================================================

  say "Installing Devise...", :green
  rails_command "generate devise:install"

  # Configure Devise mailer default URL
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: "development"

  # Generate User model with Devise
  rails_command "generate devise User"

  # Add role enum to User model
  inject_into_file "app/models/user.rb", after: "class User < ApplicationRecord\n" do
    <<-RUBY
  # Roles: :user (default), :admin
  enum :role, { user: 0, admin: 1 }, default: :user

    RUBY
  end

  # Create migration to add role to users
  generate "migration", "AddRoleToUsers role:integer"

  # Set default value for role in migration
  migration_file = Dir.glob("db/migrate/*_add_role_to_users.rb").first
  gsub_file migration_file, "add_column :users, :role, :integer", "add_column :users, :role, :integer, default: 0, null: false"

  # Add flash messages to application layout
  inject_into_file "app/views/layouts/application.html.erb", before: "    <%= yield %>" do
    <<-ERB
    <%# Flash messages %>
    <% flash.each do |type, message| %>
      <div class="<%= type == 'alert' ? 'bg-red-100 border border-red-400 text-red-700' : 'bg-green-100 border border-green-400 text-green-700' %> px-4 py-3 rounded mb-4">
        <%= message %>
      </div>
    <% end %>

    ERB
  end

  # ===========================================================================
  # Phase 3: Tailwind CSS Setup
  # ===========================================================================

  say "Installing Tailwind CSS...", :green
  rails_command "tailwindcss:install"

  # ===========================================================================
  # Phase 4: Pundit Setup
  # ===========================================================================

  say "Installing Pundit...", :green
  rails_command "generate pundit:install"

  # Include Pundit in ApplicationController
  inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
    <<-RUBY
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

    RUBY
  end

  # Replace ApplicationPolicy with enhanced version
  remove_file "app/policies/application_policy.rb"
  create_file "app/policies/application_policy.rb", <<-RUBY
# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # Role-based helper methods
  def admin?
    user&.admin?
  end

  def owner?
    record.respond_to?(:user_id) && record.user_id == user&.id
  end

  def admin_or_owner?
    admin? || owner?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in \#{self.class}"
    end

    private

    attr_reader :user, :scope

    def admin?
      user&.admin?
    end
  end
end
  RUBY

  # Create UserPolicy demonstrating role-based access
  create_file "app/policies/user_policy.rb", <<-RUBY
# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || user == record
  end

  def create?
    admin?
  end

  def update?
    admin? || user == record
  end

  def destroy?
    admin? && user != record # Admins can delete other users, but not themselves
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
  RUBY

  # ===========================================================================
  # Phase 5: Testing Setup
  # ===========================================================================

  say "Setting up tests...", :green

  # Add Devise and FactoryBot helpers to test_helper.rb
  inject_into_file "test/test_helper.rb", after: "class TestCase\n" do
    <<-RUBY
  # Devise test helpers for integration tests
  include Devise::Test::IntegrationHelpers

  # FactoryBot methods (create, build, build_stubbed, attributes_for)
  include FactoryBot::Syntax::Methods

    RUBY
  end

  # Create factories directory
  empty_directory "test/factories"

  # Create User factory
  create_file "test/factories/users.rb", force: true do
    <<-RUBY
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user\#{n}@example.com" }
    password { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end
  end
end
    RUBY
  end

  # Create policies test directory
  empty_directory "test/policies"

  # Create ApplicationPolicy test
  create_file "test/policies/application_policy_test.rb", <<-RUBY
# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @admin = create(:user, :admin)
    @record = @user
  end

  test "admin? returns true for admin users" do
    policy = ApplicationPolicy.new(@admin, @record)
    assert policy.send(:admin?)
  end

  test "admin? returns false for regular users" do
    policy = ApplicationPolicy.new(@user, @record)
    refute policy.send(:admin?)
  end

  test "admin? returns false when user is nil" do
    policy = ApplicationPolicy.new(nil, @record)
    refute policy.send(:admin?)
  end

  test "default policy methods return false" do
    policy = ApplicationPolicy.new(@user, @record)

    refute policy.index?
    refute policy.show?
    refute policy.create?
    refute policy.new?
    refute policy.update?
    refute policy.edit?
    refute policy.destroy?
  end
end
  RUBY

  # Create UserPolicy test
  create_file "test/policies/user_policy_test.rb", <<-RUBY
# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @admin = create(:user, :admin)
  end

  # Index tests
  test "admin can view user index" do
    assert UserPolicy.new(@admin, User).index?
  end

  test "regular user cannot view user index" do
    refute UserPolicy.new(@user, User).index?
  end

  # Show tests
  test "admin can view any user" do
    assert UserPolicy.new(@admin, @user).show?
  end

  test "user can view themselves" do
    assert UserPolicy.new(@user, @user).show?
  end

  test "user cannot view other users" do
    refute UserPolicy.new(@user, @admin).show?
  end

  # Create tests
  test "admin can create users" do
    assert UserPolicy.new(@admin, User).create?
  end

  test "regular user cannot create users" do
    refute UserPolicy.new(@user, User).create?
  end

  # Update tests
  test "admin can update any user" do
    assert UserPolicy.new(@admin, @user).update?
  end

  test "user can update themselves" do
    assert UserPolicy.new(@user, @user).update?
  end

  test "user cannot update other users" do
    refute UserPolicy.new(@user, @admin).update?
  end

  # Destroy tests
  test "admin can destroy other users" do
    assert UserPolicy.new(@admin, @user).destroy?
  end

  test "admin cannot destroy themselves" do
    refute UserPolicy.new(@admin, @admin).destroy?
  end

  test "regular user cannot destroy users" do
    refute UserPolicy.new(@user, @admin).destroy?
  end

  # Scope tests
  test "admin scope returns all users" do
    scope = UserPolicy::Scope.new(@admin, User).resolve
    assert_equal User.all.to_a, scope.to_a
  end

  test "user scope returns only themselves" do
    scope = UserPolicy::Scope.new(@user, User).resolve
    assert_equal [@user], scope.to_a
  end
end
  RUBY

  # ===========================================================================
  # Phase 6: Routes & Seeds
  # ===========================================================================

  say "Configuring routes and seeds...", :green

  # Add root route placeholder (commented out - user should set their own)
  inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
    <<-RUBY
  # Define your application routes here
  # Example: root "home#index"

    RUBY
  end

  # Create seeds for default admin user
  append_to_file "db/seeds.rb", <<-RUBY

# Create default admin user (only in development/test)
if Rails.env.development? || Rails.env.test?
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = :admin
  end

  puts "Default admin user created: admin@example.com / password123"
end
  RUBY

  # Run migrations and seed database
  say "Running migrations...", :green
  rails_command "db:migrate"

  say "Seeding database...", :green
  rails_command "db:seed"

  # ===========================================================================
  # Final Instructions
  # ===========================================================================

  say ""
  say "=" * 70, :green
  say "Rails application created successfully!", :green
  say "=" * 70, :green
  say ""
  say "Installed components:"
  say "  - Devise (authentication)"
  say "  - Pundit (authorization)"
  say "  - Tailwind CSS (styling)"
  say "  - Minitest (testing)"
  say "  - FactoryBot (test factories)"
  say ""
  say "Next steps:"
  say "  1. Set your root route in config/routes.rb"
  say "  2. Run 'rails test' to verify the setup"
  say ""
  say "Default admin credentials (development only):"
  say "  Email: admin@example.com"
  say "  Password: password123"
  say ""
  say "Pundit usage in controllers:"
  say "  authorize @resource        # Check authorization"
  say "  policy(@resource).show?    # Query policy directly"
  say "  policy_scope(Resource)     # Get authorized scope"
  say ""
end
