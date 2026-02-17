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

  # ===========================================================================
  # Phase 6: Routes & Seeds
  # ===========================================================================

  say "Configuring routes and seeds...", :green

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
  say "  2. Generate policies with: rails g pundit:policy <model>"
  say ""
  say "Default admin credentials (development only):"
  say "  Email: admin@example.com"
  say "  Password: password123"
  say ""
end
