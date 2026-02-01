# Rails Application Templates

A collection of Rails application templates for quickly bootstrapping new projects.

## Available Templates

### `template.rb` - Full-Stack Rails 8 Template

A complete Rails 8 application template with authentication and authorization.

**Stack:**
- **Authentication:** Devise
- **Authorization:** Pundit (policy-based)
- **Testing:** Minitest

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

- User fixtures with both regular and admin users
- Policy tests for `ApplicationPolicy` and `UserPolicy`
- Devise test helpers integrated in `test_helper.rb`

### Seeds

- Default admin user for development/test environments:
  - Email: `admin@example.com`
  - Password: `password123`

## Post-Installation Steps

1. **Set your root route** in `config/routes.rb`:
   ```ruby
   root "home#index"
   ```

2. **Seed the database** (creates default admin user):
   ```bash
   rails db:seed
   ```

3. **Run tests** to verify setup:
   ```bash
   rails test
   ```

## Pundit Usage Examples

### In Controllers

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = policy_scope(Article)
  end

  def show
    @article = Article.find(params[:id])
    authorize @article
  end

  def create
    @article = current_user.articles.build(article_params)
    authorize @article

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end
end
```

### Creating New Policies

```ruby
# app/policies/article_policy.rb
class ArticlePolicy < ApplicationPolicy
  def index?
    true # Anyone can view the index
  end

  def show?
    true # Anyone can view an article
  end

  def create?
    user.present? # Any logged-in user can create
  end

  def update?
    admin_or_owner? # Admin or article owner
  end

  def destroy?
    admin_or_owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      else
        scope.where(published: true).or(scope.where(user_id: user&.id))
      end
    end
  end
end
```

### In Views

```erb
<% if policy(@article).edit? %>
  <%= link_to "Edit", edit_article_path(@article) %>
<% end %>

<% if policy(Article).create? %>
  <%= link_to "New Article", new_article_path %>
<% end %>
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
├── fixtures/
│   └── users.yml                  # User fixtures
├── policies/
│   ├── application_policy_test.rb
│   └── user_policy_test.rb
└── test_helper.rb                 # Devise helpers added
```

## Requirements

- Ruby 3.2+
- Rails 8.0+

## License

MIT
