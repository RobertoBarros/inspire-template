module ViewComponentHelper
  def vc(component_class, **args, &block)
    render component_class.new(**args), &block
  end
end
