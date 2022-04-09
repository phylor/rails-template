# rails new -d postgresql -a propshaft -c tailwind

run 'echo 3.1.1 > .ruby-version'

gem 'cancancan'
gem 'devise'
gem 'haml'
gem 'haml-rails'
gem 'simple_form'

gem_group :development, :test do
  gem 'factory_bot'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
end

gem_group :test do
  gem 'capybara-screenshot'
end

gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/, ''
gsub_file 'Gemfile', /\s+\#.*$/, ''

run 'bundle install'

generate 'rspec:install'

append_to_file '.rspec', '--require rails_helper'

inject_into_file 'spec/rails_helper.rb', "\nrequire 'capybara/rspec'\nrequire 'capybara/rails'\nrequire 'capybara-screenshot/rspec'\n\nCapybara.asset_host = 'http://localhost:3000'\n", after: "# Add additional requires below this line. Rails is not loaded until this point!"

# FactoryBot and Devise
inject_into_file 'spec/rails_helper.rb', after: '  # config.filter_gems_from_backtrace("gem name")' do
  %(\n\n  config.include FactoryBot::Syntax::Methods\n  config.include Warden::Test::Helpers, type: :feature)
end

# Devise
generate 'devise:install'

production_url = ask 'What is the production URL? Enter without protocol (e.g. example.com).'
environment %(config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }), env: 'development'
environment %(config.action_mailer.default_url_options = { host: '#{production_url}', port: 443 }), env: 'production'

devise_model_name = ask 'What is your devise model name (e.g. User)?'
generate 'devise', devise_model_name

inject_into_file 'app/controllers/application_controller.rb', before: 'end' do
  %(\n  before_action :authenticate_#{devise_model_name.underscore}!\n)
end

# Simple Form
generate 'simple_form:install'

# HAML
run 'html2haml app/views/layouts/application.html.erb >> app/views/layouts/application.html.haml'
remove_file 'app/views/layouts/application.html.erb'

rails_command 'db:prepare'
rails_command 'db:migrate'

# cancancan

generate 'cancan:ability'

after_bundle do
  git :init
  git add: '.'
  git commit: %(-m 'Add rails project')
end
