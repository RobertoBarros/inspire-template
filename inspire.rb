####################################################
# Helpers

# replace a pattern in a file while preserving the original indentation
def gsub_file_preserving_indent(file_path, pattern, replacement_content)
  content = File.read(file_path)
  new_content = content.gsub(/^(\s*)#{Regexp.escape(pattern)}/) do
    indent = $1
    replacement_content.split("\n").map { |line| "#{indent}#{line}" }.join("\n")
  end
  File.write(file_path, new_content)
end

####################################################
# Gemfile

# Gems for all environments
inject_into_file "Gemfile", before: "group :development, :test do\n" do
<<-RUBY
# ViewComponent for building reusable components
gem "view_component"
# form builder for ViewComponent (compatible with ViewComponent 4)
gem "view_component-form", github: "DEfusion/view_component-form", branch: "view-component-4-support"
# Devise for authentication
gem "devise"
# CSS with Tailwind via cssbundling-rails
gem "cssbundling-rails"
# Live reload with Hotwire Spark
gem "hotwire-spark"
# Icons (Heroicons by default)
gem "rails_icons"

RUBY
end

# Gems for development only
inject_into_file "Gemfile", after: "group :development do\n" do
<<-RUBY

# Letter Opener for emails
  gem "letter_opener"
RUBY
end

run "bundle install --quiet" # Install the gems


####################################################
# Live reload with Hotwire Spark
inject_into_file "config/environments/development.rb",
<<-RUBY,

  # hotwire-spark monitoring path
  config.hotwire.spark.html_paths += %w[ app/components ]
RUBY
  after: "Rails.application.configure do\n"


####################################################
# CSS with Tailwind via cssbundling-rails
run "bin/rails css:install:tailwind"
gsub_file "package.json", "application.tailwind.css", "application.css"
run "mv app/assets/stylesheets/application.tailwind.css app/assets/stylesheets/application.css"
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


####################################################
# DaisyUI plugin for Tailwind
run "yarn add daisyui@latest"
append_to_file "app/assets/stylesheets/application.css" do
  <<~CODE

    @plugin "daisyui" { themes: all; }
  CODE
end


####################################################
# Rails Icons
run "bin/rails generate rails_icons:install --libraries=heroicons"


####################################################
# Devise for authentication
run "bin/rails generate devise:install"
run "bin/rails generate devise User"


####################################################
# Letter Opener for emails
inject_into_file "config/environments/development.rb",
<<-RUBY,

  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

RUBY
  after: "Rails.application.configure do\n"




####################################################
# ApplicationController setup
inject_into_class "app/controllers/application_controller.rb", "ApplicationController",
<<-RUBY
  layout :layout_by_resource
  before_action :authenticate_user!
  default_form_builder TailwindBuilder
RUBY

inject_into_file "app/controllers/application_controller.rb",
<<-RUBY,
  private

  def layout_by_resource
    if devise_controller? && !user_signed_in?
      "unauthenticated" # signin, signup, password pages
    else
      "application" # default layout with sidebar
    end
  end
RUBY
  before: "end"


####################################################
# Clone the Inspire repository for copy template code
tmp_dir = "tmp/inspire-template-clone"

if ENV["INSPIRE_TEMPLATE_PATH"]
  local_path = File.expand_path(ENV["INSPIRE_TEMPLATE_PATH"])
  run "mkdir -p #{tmp_dir}"
  run "cp -R #{local_path}/. #{tmp_dir}/"
else
  repository = "https://github.com/RobertoBarros/inspire-template.git"
  run %(git clone --depth=1 #{repository} #{tmp_dir})
end

####################################################
# Copy tailwind-form components and helpers
run "mkdir -p app/components/tailwind_form"
run "cp #{tmp_dir}/tailwind_form/* app/components/tailwind_form/"
run "cp #{tmp_dir}/helpers/* app/helpers/"

run "mkdir -p app/views/devise"
run "cp -r #{tmp_dir}/views/devise/* app/views/devise/"


####################################################
# Layouts

# duplicate application layout to create an unauthenticated layout
run "cp app/views/layouts/application.html.erb app/views/layouts/unauthenticated.html.erb"

unauthenticated_body = File.read("#{tmp_dir}/views/layouts/unauthenticated_body.html.erb")
gsub_file_preserving_indent "app/views/layouts/unauthenticated.html.erb", "<%= yield %>", unauthenticated_body

authenticated_body = File.read("#{tmp_dir}/views/layouts/authenticated_body.html.erb")
gsub_file_preserving_indent "app/views/layouts/application.html.erb", "<%= yield %>", authenticated_body

run "cp -r #{tmp_dir}/views/layouts/_* app/views/layouts/"


####################################################
# Rails Routes
inject_into_file "config/routes.rb",
<<-RUBY,

  authenticated :user do
    root to: "pages#dashboard", as: :authenticated_root
  end
  root to: "pages#home"
RUBY
  after: "Rails.application.routes.draw do\n"


####################################################
# PagesController
run "bin/rails generate controller Pages home dashboard --skip-routes"
inject_into_class "app/controllers/pages_controller.rb", "PagesController" do
  "  skip_before_action :authenticate_user!, only: :home\n\n"
end

inject_into_file "app/controllers/pages_controller.rb",
<<-RUBY,

    render layout: "unauthenticated" # Use this layout to not render sidebar
RUBY
  after: "def home\n"

run "mkdir -p app/views/pages"
run "cp -r #{tmp_dir}/views/pages/* app/views/pages/"


####################################################
# Assets copy
run "cp -r #{tmp_dir}/assets/images/* app/assets/images/"


####################################################
# Cleanup before bundle
run "bin/rails db:drop db:create db:migrate db:seed"

# remove the temporary clone
run %(rm -rf #{tmp_dir})


####################################################
# After bundle tasks
after_bundle do
  # A Stimulus controller for showing notifications.
  run "yarn add @stimulus-components/notification"
  path = "app/javascript/controllers/application.js"
  inject_into_file path, after: "const application = Application.start()\n" do
    <<~JS
      // Stimulus controller for showing notifications.
      // see app/views/shared/_flashes.html.erb for usage
      import Notification from "@stimulus-components/notification";
      application.register("notification", Notification);

    JS

  end

  # Initial Git commit
  git :init
  git add: "."
  git commit: "-m 'Made with https://github.com/RobertoBarros/inspire-template'"
end
