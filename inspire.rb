# Live reload with Hotwire Spark
########################################
inject_into_file "Gemfile", after: "group :development, :test do\n" do
  "  gem \"hotwire-spark\"\n"
end
inject_into_file "config/environments/development.rb",
  "  # hotwire-spark monitoring path\n  config.hotwire.spark.html_paths += %w[ app/components ]\n",
  after: "Rails.application.configure do\n"
