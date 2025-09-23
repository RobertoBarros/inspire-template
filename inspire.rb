
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

    @source "../../../public/*.html";
    @source "../../../app/helpers/**/*.rb";
    @source "../../../app/javascript/**/*.js";
    @source "../../../app/views/**/*";
    @source "../../../app/components/**/*.rb";
    @source "../../../app/components/**/*";
  CODE
end


# Reset and prepare database
########################################
# Drops, creates, migrates and seeds the database to ensure a clean start
run "bin/rails db:drop db:create db:migrate db:seed"
