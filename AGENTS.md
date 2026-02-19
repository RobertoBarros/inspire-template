# AGENTS.md

## Objetivo do repositorio
Este projeto e um template Rails aplicado via `rails new -m inspire.rb`.
As mudancas aqui impactam projetos novos gerados pelo script.

## Stack e escopo
- Ruby on Rails template (`inspire.rb`)
- UI com Tailwind CSS + DaisyUI
- Autenticacao com Devise
- Componentizacao de formularios com `view_component` + `view_component-form`
- Assets e views-base copiados deste repositorio para o app gerado

## Mapa do projeto
- `inspire.rb`: fluxo principal do template (instalacao de gems, geradores, copias e injections)
- `tailwind_form/`: componentes usados pelo `TailwindBuilder`
- `helpers/tailwind_builder.rb`: builder padrao do formulario no app gerado
- `helpers/view_component_helper.rb`: helper `vc(...)`
- `views/`: layouts, paginas e telas do Devise que serao copiadas para o app final
- `assets/`: imagens e CSS de mailer copiados para o app final
- `readme.md`: documentacao de uso
- `deploy.sh`: script local de smoke test do template

## Regras para agentes
- Mantenha alteracoes pequenas, focadas e coerentes com Rails conventions.
- Preserve compatibilidade com o fluxo atual do `inspire.rb`; ao mover/renomear arquivos, atualize os comandos `cp`/`inject`.
- Nao introduza dependencias novas sem necessidade clara no template.
- Em views ERB, mantenha padrao existente com Tailwind/DaisyUI.
- Evite alterar comportamento global sem justificativa (ex.: `ActionView::Base.field_error_proc`).
- Nao remova funcionalidades base esperadas: Devise, layouts auth/unauth, flashes com Stimulus notification.
- Em testes de integracao, prefira validar por URL/rota (ex.: `path`, `assert_redirected_to`) em vez de texto renderizado na pagina.

## Checklist antes de concluir
1. Validar sintaxe Ruby:
   - `ruby -c inspire.rb`
   - `ruby -c helpers/tailwind_builder.rb`
2. Revisar se caminhos de copia continuam validos (`views/`, `assets/`, `tailwind_form/`, `helpers/`).
3. Conferir que injections no `inspire.rb` ainda batem com strings-alvo do Rails gerado.
4. Se alterar UX/layouts, revisar `views/layouts/authenticated_body.html.erb`, `views/layouts/unauthenticated_body.html.erb` e `views/layouts/_flashes.html.erb`.
5. Atualizar `readme.md` quando houver mudanca funcional no template.

## Smoke test recomendado
Quando possivel, executar geracao de app de teste com template local:

```bash
INSPIRE_TEMPLATE_PATH=/caminho/para/inspire-template rails new \
  -d postgresql \
  -j esbuild \
  -m /caminho/para/inspire-template/inspire.rb \
  test_inspire
```

Depois, validar bootstrap do app gerado (`bin/dev`, fluxo de login e layouts).

Exemplo completo usado localmente:

```bash
cd ~/code && rm -rf test-inspire && \
INSPIRE_TEMPLATE_PATH=~/code/inspire-template rails new \
  -d postgresql \
  -j esbuild \
  -m ~/code/inspire-template/inspire.rb \
  test-inspire && \
cd test-inspire && \
code . & \
bin/dev
```
