source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# use devise for authentication
gem "devise", "~> 4.9"

# use devise token_authenticatable for token-based authentication
gem "devise_token_auth", "~> 1.2"

# use devise il18n for internationalization
gem "devise-i18n", "~> 1.0"



group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 7.1", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Use RSpec for testing [https://rspec.info/]
  gem "rspec-rails", "~> 8.0.0"

  # Use Factory Bot for setting up Ruby objects as test data 今まで使用してきたFixtureの代わり
  gem "factory_bot_rails", "~> 6.0"

  # Use Faker for generating fake data
  gem "faker", "~> 3.0"

  # Use byebug for debugging これがあると、デバック最中にコードが途中で止まる
  gem "byebug", platforms: %i[ mri windows ]

  # User kill N+1 queries
  gem "bullet", "~> 8.0"
  # 環境変数を管理するgem
  gem "dotenv-rails", "~> 2.1"
  # gemの脆弱性チェック
  # bundle exec bundler-audit check で脆弱性確認
  # bundle exec bundler-audit update で脆弱性情報を更新
  gem "bundler-audit", require: false
end


group :development do
  # Use the Annotaterb gem to annotate your models with schema information
  # This is useful for development and debugging, but not recommended for production.
  gem "annotaterb", "~> 4.1", require: false
  gem "letter_opener_web", "~> 3.0"
end

group :test do
  gem "simplecov", "~> 0.21.0", require: false
end
