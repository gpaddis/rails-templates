# Rails Application Templates

A collection of Rails application templates for quickly bootstrapping new projects.

## Available Templates

### `template.rb` - Full-Stack Rails 8 Template

A complete Rails 8 application template with authentication and authorization.

**Stack:**
- **Authentication:** Devise
- **Authorization:** Pundit (policy-based)
- **CSS:** Tailwind CSS
- **Testing:** Minitest with FactoryBot

## Usage

### From Local Path

```bash
rails new myapp -m /path/to/rails-templates/template.rb
```

### From GitHub (Raw URL)

```bash
rails new myapp -m https://raw.githubusercontent.com/gpaddis/rails-templates/main/template.rb
```

### With Additional Rails Options

```bash
# Skip Git initialization
rails new myapp -m template.rb --skip-git

# Use PostgreSQL
rails new myapp -m template.rb -d postgresql

# Skip system tests
rails new myapp -m template.rb --skip-system-test
```

## What's Included

### Devise Authentication

- User model with standard Devise modules:
  - `database_authenticatable`
  - `registerable`
  - `recoverable`
  - `rememberable`
  - `validatable`
- Flash message display in application layout
- Mailer configuration for development

### Pundit Authorization

- Role-based enum on User model (`:user`, `:admin`)
- `ApplicationPolicy` with helper methods:
  - `admin?` - checks if user has admin role
  - `owner?` - checks if user owns the record (via `user_id`)
  - `admin_or_owner?` - combines both checks
- `UserPolicy` demonstrating role-based access patterns
- Authorization error handling in `ApplicationController`

### Testing

- FactoryBot factories for user creation (with `:admin` trait)
- Policy tests for `ApplicationPolicy` and `UserPolicy`
- Devise and FactoryBot helpers integrated in `test_helper.rb`

### Seeds

- Default admin user for development/test environments:
  - Email: `admin@example.com`
  - Password: `password123`

## Post-Installation Steps

1. **Set your root route** in `config/routes.rb`:
   ```ruby
   root "home#index"
   ```

2. **Run tests** to verify setup:
   ```bash
   rails test
   ```

## File Structure Created

```
app/
├── controllers/
│   └── application_controller.rb  # Pundit integration
├── models/
│   └── user.rb                    # Role enum added
├── policies/
│   ├── application_policy.rb      # Base policy with helpers
│   └── user_policy.rb             # Example policy
└── views/
    └── layouts/
        └── application.html.erb   # Flash messages added

config/
├── environments/
│   └── development.rb             # Mailer URL options
└── routes.rb                      # Devise routes added

db/
├── migrate/
│   ├── *_devise_create_users.rb
│   └── *_add_role_to_users.rb
└── seeds.rb                       # Admin user seed

test/
├── factories/
│   └── users.rb                   # User factory
├── policies/
│   ├── application_policy_test.rb
│   └── user_policy_test.rb
└── test_helper.rb                 # Devise & FactoryBot helpers
```

## Requirements

- Ruby 3.2+
- Rails 8.0+

## License

MIT
