module TailwindForm::FieldModule
  def self.template
    <<~ERB
      <fieldset class="fieldset">
        <legend class="fieldset-legend"><%= label_text %> <%= " *" if required? %></legend>
        <label class="w-full input <%= "input-error" if method_errors? %>">
          <%= render_parent_to_string %>
          <% if method_errors? %>
            <%= helpers.icon "exclamation-circle", class: "h-[1.5em] opacity-50 text-error" %>
          <% end %>
        </label>
        <% if method_errors? %>
          <p class="text-error"><%= method_errors.join(", ") %></p>
        <% end %>
      </fieldset>
    ERB
  end
end
