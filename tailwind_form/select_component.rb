class TailwindForm::SelectComponent < ViewComponent::Form::SelectComponent
  def initialize(form, object_name, method_name, choices = nil, options = {}, html_options = {})
    html_options[:data] = {
      controller: "tom-select"
    }.merge(html_options[:data] || {})
    super
  end
end
