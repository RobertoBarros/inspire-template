# Inspire Template

## O que é?

Inspire template é um template para novas aplicações Ruby on Rails que adiciona funcionalidades básicas e comuns a maiora das aplicações web

## Como usar

Inicie uma nova aplicação rais com o inspire template. Por padrão utiliza esbuild para assets javascript e banco de dados PostgreSQL

```
rails new \
  -d postgresql \
  -j esbuild
  -m [address] \
  CHANGE_TO_YOUR_RAILS_APP_NAME

```

## Funcionalidades

### Hot Reload

Utiliza https://github.com/hotwired/spark para auto-reload
