class TailwindForm::PhoneFieldComponent < ViewComponent::Form::TextFieldComponent
  def initialize(form, object_name, method_name, options = {})
    @input_name = "#{object_name}[#{method_name}]"
    super
  end

  def html_class
    "hidden"
  end
end
