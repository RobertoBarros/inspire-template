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
# Gemfile

# Gems for all environments
inject_into_file "Gemfile", before: "group :development, :test do\n" do
<<-RUBY
# ViewComponent for building reusable components
gem "view_component"
# form builder for ViewComponent (compatible with ViewComponent 4)
gem "view_component-form"
# Devise for authentication
gem "devise"
gem 'devise-i18n'
# CSS with Tailwind via cssbundling-rails
gem "cssbundling-rails"
# Live reload with Hotwire Spark
gem "hotwire-spark"
# Icons (Heroicons by default)
gem "rails_icons"
# Email inlined CSS
gem "premailer-rails"
# GetText for UI translation strings
gem "gettext_i18n_rails"
gem "gettext", ">=3.0.2", require: false
# Rails I18n defaults (dates, numbers, etc.)
gem "rails-i18n"

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

gsub_file "config/initializers/devise.rb", "# config.mailer = 'Devise::Mailer'", "config.mailer = \"DeviseMailer\""

create_file "app/mailers/devise_mailer.rb",
<<-RUBY
  class DeviseMailer < Devise::Mailer
    helper :application
    include Devise::Controllers::UrlHelpers
    default template_path: "devise/mailer"
    layout "mailer"
  end
RUBY

# Copy devise views
run "mkdir -p app/views/devise"
run "cp -r #{tmp_dir}/views/devise/* app/views/devise/"

# Default admin user seed
append_to_file "db/seeds.rb" do
  <<~RUBY

    User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "123123"
      user.password_confirmation = "123123"
    end
  RUBY
end

####################################################
# Email config

# Development environment - Letter Opener
inject_into_file "config/environments/development.rb",
<<-RUBY,

  # Letter Opener for email previews
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
RUBY
  after: "Rails.application.configure do\n"

# copy mailer layout and stylesheet
run "cp #{tmp_dir}/views/layouts/mailer.html.erb app/views/layouts/mailer.html.erb"
run "cp #{tmp_dir}/assets/stylesheets/mailer.css app/assets/stylesheets/mailer.css"


####################################################
# Internationalization (GetText + Rails I18n)
inject_into_class "config/application.rb", "Application",
<<-RUBY
    config.i18n.available_locales = %i[pt-BR en es]
    config.i18n.default_locale = :"pt-BR"
RUBY

create_file "config/initializers/gettext_i18n_rails.rb",
<<-RUBY
  FastGettext.add_text_domain "app", path: "locale", type: :po
  FastGettext.default_available_locales = ["pt_BR", "en", "es"]
  FastGettext.default_text_domain = "app"

  # We keep ActiveRecord attribute translations in config/locales/*.yml
  Rails.application.config.gettext_i18n_rails.use_for_active_record_attributes = false
RUBY


run "mkdir -p app/controllers/concerns"
create_file "app/controllers/concerns/internationalization.rb",
<<-RUBY
  module Internationalization
    extend ActiveSupport::Concern

    included do
      around_action :switch_locale

      private

      def switch_locale(&action)
        locale = locale_from_url || locale_from_headers || I18n.default_locale
        response.set_header "Content-Language", locale
        I18n.with_locale locale, &action
      end

      def locale_from_url
        locale = params[:locale]
        locale if I18n.available_locales.map(&:to_s).include?(locale)
      end

      def locale_from_headers
        header = request.env["HTTP_ACCEPT_LANGUAGE"]
        return if header.nil?

        locales = parse_header(header)
        return if locales.empty?

        detect_from_available(locales)
      end

      def parse_header(header)
        header.gsub(/\\s+/, "").split(",").map do |language_tag|
          locale, quality = language_tag.split(/;q=/i)
          quality = quality ? quality.to_f : 1.0
          [locale, quality]
        end.reject do |(locale, quality)|
          locale == "*" || quality.zero?
        end.sort_by do |(_, quality)|
          quality
        end.map(&:first)
      end

      def detect_from_available(locales)
        locales.reverse.find { |l| I18n.available_locales.any? { |al| match?(al, l) } }
      end

      def match?(str1, str2)
        str1.to_s.casecmp(str2.to_s).zero?
      end

      def default_url_options
        { locale: I18n.locale }
      end
    end
  end
RUBY

run "mkdir -p config/locales"

run "cp #{tmp_dir}/config/locales/*.yml config/locales"

run "mkdir -p locale"
run "LANGUAGE=pt_BR rake gettext:add_language"
run "LANGUAGE=en rake gettext:add_language"
run "LANGUAGE=es rake gettext:add_language"

####################################################
# ApplicationController setup
inject_into_class "app/controllers/application_controller.rb", "ApplicationController",
<<-RUBY
  include Internationalization
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
# Copy tailwind-form components and helpers
run "mkdir -p app/components/tailwind_form"
run "cp #{tmp_dir}/tailwind_form/* app/components/tailwind_form/"
run "cp #{tmp_dir}/components/* app/components/"
run "cp #{tmp_dir}/helpers/* app/helpers/"



####################################################
# Layouts

# duplicate application layout to create an unauthenticated layout
#
#
gsub_file "app/views/layouts/application.html.erb", "<%# Includes all stylesheet files in app/assets/stylesheets %>", "<%# Include only stylesheet in app/assets/stylesheets/application.css - Use @import to add additional stylesheets %>"
gsub_file "app/views/layouts/application.html.erb", "stylesheet_link_tag :app", "stylesheet_link_tag \"application\""

run "cp app/views/layouts/application.html.erb app/views/layouts/unauthenticated.html.erb"

unauthenticated_body = File.read("#{tmp_dir}/views/layouts/unauthenticated_body.html.erb")
gsub_file_preserving_indent "app/views/layouts/unauthenticated.html.erb", "<%= yield %>", unauthenticated_body

authenticated_body = File.read("#{tmp_dir}/views/layouts/authenticated_body.html.erb")
gsub_file_preserving_indent "app/views/layouts/application.html.erb", "<%= yield %>", authenticated_body

run "cp -r #{tmp_dir}/views/layouts/_* app/views/layouts/"


####################################################
# Rails Routes
create_file "config/routes.rb",
<<-RUBY,
Rails.application.routes.draw do
  scope "(:locale)", locale: /\#{I18n.available_locales.join("|")}/ do
    devise_for :users

    authenticated :user do
      root to: "pages#dashboard", as: :authenticated_root
    end

    root to: "pages#home"
  end
end
RUBY
  force: true


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

# Generate translation template file
run "rake gettext:find"

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
