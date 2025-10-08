# Inspire Template

## O que é?

Inspire template é um template para novas aplicações Ruby on Rails que adiciona funcionalidades básicas e comuns a maiora das aplicações web

## Como usar

Inicie uma nova aplicação rais com o inspire template. Por padrão utiliza esbuild para assets javascript e banco de dados PostgreSQL

```
rails new \
  -d postgresql \
  -j esbuild \
  -m https://raw.githubusercontent.com/RobertoBarros/inspire-template/refs/heads/main/inspire.rb \
  CHANGE_TO_YOUR_RAILS_APP_NAME
```

## Funcionalidades

### Hot Reload

Utiliza https://github.com/hotwired/spark para auto-reload

### Tailwind

O framework de CSS Tailwind é instalado e configurado automaticamente usando o cssbundling-rails.
O arquivo principal de estilos é `app/assets/stylesheets/application.css`

### DaisyUI

### Icons

Utiliza a gem `rails_icons` para facilitar o uso de ícones SVG em views e componentes. O set `heroicons` é instalado por padrão.

### Flash Messages

O template inclui um partial `_flashes.html.erb` para exibir mensagens de `notice` e `alert` de forma elegante, utilizando o controller Stimulus `"notification"`.

O partial é automaticamente incluído no layout padrão da aplicação. Ele exibe toasts com transições suaves, desaparecendo após 4 segundos.

Essas mensagens são renderizadas automaticamente quando você define `flash[:notice]` ou `flash[:alert]` em seus controllers.
