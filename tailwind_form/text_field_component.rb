class TailwindForm::TextFieldComponent < ViewComponent::Form::TextFieldComponent
  include TailwindForm::FieldModule

  erb_template TailwindForm::FieldModule.template
end
