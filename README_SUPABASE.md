# Olympius — versão com Supabase

## Arquivos

- `index_supabase.html` — site já adaptado para Supabase.
- `supabase.sql` — banco, tabelas, RLS, criação automática de perfil, XP e curtidas.

## 1. Criar o banco

1. Crie um projeto no Supabase.
2. Abra **SQL Editor**.
3. Cole o conteúdo de `supabase.sql`.
4. Execute.

## 2. Pegar as chaves

No Supabase, abra as configurações de API/Connect e copie:

- Project URL
- Publishable key (ou anon key, dependendo da interface do projeto)

No início do `index_supabase.html`, substitua:

```js
const SUPABASE_URL = "COLE_AQUI_A_URL_DO_SEU_PROJETO";
const SUPABASE_PUBLISHABLE_KEY = "COLE_AQUI_A_SUA_PUBLISHABLE_KEY";
```

Nunca coloque a `service_role` key no HTML.

## 3. Autenticação

O site agora usa Supabase Auth com e-mail + senha.

O cadastro pede:

- usuário
- e-mail
- senha
- confirmação da senha

O nome de usuário fica na tabela `profiles`.

Se a confirmação de e-mail estiver ativada no Supabase, o usuário precisa confirmar o e-mail antes do primeiro login.

## 4. Netlify

Você pode manter o Netlify como hospedagem.

No GitHub, deixe o arquivo principal como:

`index.html`

Portanto, depois de testar, renomeie:

`index_supabase.html` → `index.html`

Se existirem pastas `assets/` usadas pelo site, mantenha a mesma estrutura.

## 5. O que ficou online

Agora estes dados ficam no Supabase:

- contas
- autenticação
- nome de usuário
- XP
- nível
- medalhas
- ranking
- posts
- curtidas

O Supabase Auth mantém a sessão do usuário no navegador para que ele continue autenticado em visitas futuras no mesmo dispositivo; a conta e os dados ficam no banco e podem ser acessados de outros dispositivos após novo login.

## 6. Segurança

As senhas não são salvas pelo site em `localStorage`. A autenticação é feita pelo Supabase Auth.

As tabelas possuem Row Level Security (RLS). O XP é alterado por uma função do banco associada ao usuário autenticado, em vez de o navegador simplesmente poder escrever qualquer valor de XP.

## 7. Observação

O layout e a maior parte das funcionalidades originais foram preservados. O chatbot continua sendo a resposta simulada que já existia no HTML; ele não foi transformado em uma API de IA.
