class TailwindForm::FileFieldComponent < ViewComponent::Form::FileFieldComponent
  def html_class
    "file-input"
  end
end
