# Live reload with Hotwire Spark
inject_into_file "Gemfile", after: "group :development, :test do\n" do
  <<~RUBY
    gem "hotwire-spark"
  RUBY
end
inject_into_file "config/environments/development.rb",
  <<~RUBY,
    # hotwire-spark monitoring path
    config.hotwire.spark.html_paths += %w[ app/components ]
  RUBY
  after: "Rails.application.configure do\n"


# CSS with Tailwind via cssbundling-rails
inject_into_file "Gemfile", before: "group :development, :test do\n" do
  <<~RUBY
    # CSS with Tailwind via cssbundling-rails
    gem "cssbundling-rails"

  RUBY
end
run "bin/rails css:install:tailwind"
gsub_file "package.json", "application.tailwind.css", "application.css"

run "mv app/assets/stylesheets/application.tailwind.css app/assets/stylesheets/application.css"

# DaisyUI plugin for Tailwind
run "yarn add daisyui@latest"
append_to_file "app/assets/stylesheets/application.css" do
  <<~CODE

    @plugin "daisyui" { themes: all; }
  CODE
end

# Add additional paths to be monitored by tailwind
append_to_file "app/assets/stylesheets/application.css" do
  <<~CODE

    /* Additional paths to be monitored by Tailwind */
    @source "../../../public/*.html";
    @source "../../../app/helpers/**/*.rb";
    @source "../../../app/javascript/**/*.js";
    @source "../../../app/views/**/*";
    @source "../../../app/components/**/*.rb";
    @source "../../../app/components/**/*";
  CODE
end

# ViewComponent for building reusable components
inject_into_file "Gemfile", before: "group :development, :test do\n" do
  <<~RUBY
    # ViewComponent for building reusable components
    gem "view_component"
    # form builder for ViewComponent (compatible with ViewComponent 4)
    gem "view_component-form", github: "DEfusion/view_component-form", branch: "view-component-4-support"
  RUBY
end
run "bundle install --quiet"

# Devise for authentication
inject_into_file "Gemfile", before: "group :development, :test do\n" do
  <<~RUBY
    # Devise for authentication
    gem "devise"

  RUBY
end
run "bundle install --quiet"

# Install Devise and configure default URL options
run "bin/rails generate devise:install"

# Generate Devise User model
run "bin/rails generate devise User"

# Configure ApplicationController with authentication and default form builder
inject_into_class "app/controllers/application_controller.rb", "ApplicationController", <<-RUBY

  before_action :authenticate_user!
  default_form_builder TailwindBuilder

  def after_sign_in_path_for(resource_or_scope)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
RUBY

# Clone the Inspire repository for copy example code
tmp_dir = "tmp/inspire-template-clone"
repository = "https://github.com/RobertoBarros/inspire-template.git"
run %(git clone --depth=1 #{repository} #{tmp_dir})

# Copy tailwind-form components and helpers
run "mkdir -p app/components/tailwind_form"
run "cp #{tmp_dir}/tailwind_form/* app/components/tailwind_form/"
run "cp #{tmp_dir}/helpers/* app/helpers/"

run "mkdir -p app/views/devise"
run "cp -r #{tmp_dir}/views/devise/* app/views/devise/"

gsub_file "app/views/layouts/application.html.erb", "<%= yield %>", "<%= render user_signed_in? ? \"layouts/authenticated\" : \"layouts/unauthenticated\" %>"
run "cp -r #{tmp_dir}/views/layouts/_* app/views/layouts/"

# Set root route
inject_into_file "config/routes.rb", <<-RUBY,
  get "dashboard", to: "pages#dashboard", as: :dashboard
  root to: "pages#home"
RUBY
  after: "Rails.application.routes.draw do\n"

run "bin/rails generate controller Pages home dashboard --skip-routes"

inject_into_class "app/controllers/pages_controller.rb", "PagesController" do
  "  skip_before_action :authenticate_user!, only: :home\n\n"
end

run "mkdir -p app/views/pages"
run "cp -r #{tmp_dir}/views/pages/* app/views/pages/"
run "cp -r #{tmp_dir}/assets/images/* app/assets/images/"


# remove the temporary directory
run %(rm -rf #{tmp_dir})

# Reset and prepare database
########################################
run "bin/rails db:drop db:create db:migrate db:seed"
