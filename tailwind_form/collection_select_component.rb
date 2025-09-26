class TailwindForm::CollectionSelectComponent < ViewComponent::Form::CollectionSelectComponent
  def initialize(form, object_name, method_name, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:data] = {
      controller: "tom-select"
    }.merge(html_options[:data] || {})
    super
  end
end
