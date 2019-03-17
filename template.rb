gem 'bootstrap'
gem 'devise'
gem 'haml'
gem 'haml-rails'
gem 'jquery-rails'
gem 'pg'
gem 'simple_form'

gem_group :development, :test do
  gem 'rspec-rails'
end

gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/, ''
gsub_file 'Gemfile', /\s+\#.*$/, ''

run 'bundle install'

# Postgres
remove_file 'config/database.yml'
file 'config/database.yml', <<-CODE
  default: &default
    adapter: postgresql
    port: 5432
    pool: 5
    timeout: 5000
    user: postgres

  development:
    <<: *default
    database: #{app_name}_development

  test:
    <<: *default
    database: #{app_name}_test

  production:
    <<: *default
    database: #{app_name}_production
CODE

# Devise
generate 'devise:install'

production_url = ask 'What is the production URL? Enter without protocol (e.g. exmaple.com).'
environment %(config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }), env: 'development'
environment %(config.action_mailer.default_url_options = { host: '#{production_url}', port: 443 }), env: 'production'

devise_model_name = ask 'What is your devise model name (e.g. User)?'
generate 'devise', devise_model_name

inject_into_file 'app/controllers/application_controller.rb', before: 'end' do
  %(\n  before_action :authenticate_#{devise_model_name.underscore}!\n)
end

# Simple Form
generate 'simple_form:install', '--bootstrap'

remove_file 'app/assets/stylesheets/application.css'
file 'app/assets/stylesheets/application.scss', <<-CODE
  @import "bootstrap";
CODE

inject_into_file 'app/assets/javascripts/application.js', before: '//= require_tree .' do
  %(//= require jquery3\n//= require popper\n//= require bootstrap\n)
end

# HAML
run 'html2haml app/views/layouts/application.html.erb >> app/views/layouts/application.html.haml'
remove_file 'app/views/layouts/application.html.erb'

rails_command 'db:create'
rails_command 'db:migrate'

after_bundle do
  git :init
  git add: '.'
  git commit: %(-m 'Add rails project')
end
