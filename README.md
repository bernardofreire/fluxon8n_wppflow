# Atendimento WhatsApp · n8n + Meta + Odoo

Modelo de automação de atendimento no WhatsApp para **cada empresa parceira**.
Tudo gira em torno de 3 peças:

- **Meta (WhatsApp Cloud API)** — recebe/envia as mensagens e hospeda os *Flows* (telas interativas).
- **n8n** — o cérebro: recebe o webhook, decide o que fazer e responde.
- **Odoo** — a fonte da verdade do negócio (catálogo, clientes, pedidos/POS).

A pasta **`empresas/EMPRESA X/`** é o **molde**: para cada nova empresa parceira, duplicamos essa
pasta dentro de `empresas/` (ex.: `empresas/EMPRESA Y/`) e trocamos as configurações. A pasta
**`COMUM/`** tem o que é compartilhado por **todas** as empresas.

---

## 1. Como tudo se conecta

```
Parceiro  ──associado a──►  BM (Business Manager) da empresa
                                  │
                                  ├── App WhatsApp  ──►  1 URL de webhook (única por BM)
                                  │
                                  └── WABA(s)  ──►  números (cada número = phone_number_id)
```

Conceitos da Meta, do maior para o menor:

| Termo | O que é |
|-------|---------|
| **BM** (Business Manager) | A conta da empresa na Meta. Nós (parceiro) ficamos associados a ela. |
| **App** | O aplicativo WhatsApp dentro da BM. Define **uma URL de webhook** que recebe tudo. |
| **WABA** | WhatsApp Business Account. Uma BM pode ter várias (ex.: uma p/ restaurante, uma p/ clínica). |
| **Número** (`phone_number_id`) | O telefone em si. É por ele que sabemos para qual fluxo mandar a mensagem. |

> **Regra de ouro:** é **1 URL de webhook por BM**. Todos os números e todas as WABAs daquela
> empresa chegam nessa mesma URL. Quem separa "o que é de quem" é o n8n.

---

## 2. O caminho de uma mensagem (ponta a ponta)

```
Cliente no WhatsApp
      │  envia mensagem
      ▼
Meta (Cloud API)  ──POST──►  [WEBHOOK META]  (n8n, 1 URL por BM)
                                   │  1. responde 200 OK na hora (ACK)
                                   │  2. descarta ruído (status de entrega, eventos do sistema)
                                   │  3. Filtro 1: por waba_id   → qual WABA?
                                   │  4. Filtro 2: por phone_number_id → qual número?
                                   ▼
                          [FLUXO PRINCIPAL]  (sub-workflow do restaurante)
                                   │  decide a etapa e dispara o Flow do cardápio
                                   ▼
Cliente abre o Flow  ──navega/escolhe──►  Meta  ──POST criptografado──►  [BACKEND DO FLOW]
                                                                              │  busca catálogo no Odoo
                                                                              │  monta as telas e devolve
                                                                              ▼
Cliente finaliza  ─────────────────────────────────────────►  pedido criado no Odoo (POS)
                                                                              │
Odoo muda o status (aceito, saiu p/ entrega...)  ──POST──►  [ODOO CALLBACK]  ──►  avisa o cliente
```

Resumo das peças do fluxo do restaurante:

| Peça | Plataforma | Papel |
|------|-----------|-------|
| **WEBHOOK META** | n8n | Porta de entrada da BM. Filtra ruído e roteia por WABA + número. |
| **FLUXO PRINCIPAL** | n8n | Roteador do restaurante. Decide a etapa pelo tipo da mensagem + Odoo e dispara o Flow. |
| **FLOW (TELAS)** | Meta | A definição visual do Flow (telas do cardápio) publicada na Meta. |
| **BACKEND DO FLOW** | n8n | Endpoint *data exchange*: descriptografa, busca o catálogo no Odoo e devolve as telas dinâmicas. |
| **ODOO CALLBACK** | n8n | Recebe a mudança de status do pedido (vinda do Odoo) e notifica o cliente. |

> **Estado sem banco de "store":** o FLUXO PRINCIPAL é **stateless** — a etapa vem carimbada no
> tipo da mensagem (texto = início, clique de botão = menu, `nfm_reply` = pedido concluído) e o
> "quem é o cliente / tem pedido aberto?" vem do **Odoo** a cada mensagem. A tabela
> `wa_session` (em `COMUM/postgres/`) só guarda contexto leve de conversa, com chave
> `(phone_number_id, telefone)` — por isso uma tabela única serve todas as empresas sem misturar.

---

## 3. Estrutura de pastas

```
.
├── empresas/                          ← uma pasta por empresa parceira
│   └── EMPRESA X/                      ← MOLDE: duplicar para cada nova empresa
│       ├── n8n/
│       │   └── [EMPRESA X] - WEBHOOK META.json          (porta de entrada da BM)
│       └── restaurante/                                  (um fluxo de negócio)
│           ├── meta/
│           │   └── [EMPRESA X] - RESTAURANTE - FLOW (TELAS).json     (sobe na Meta)
│           ├── n8n/
│           │   ├── [EMPRESA X] - RESTAURANTE - FLUXO PRINCIPAL.json  (roteador)
│           │   └── [EMPRESA X] - RESTAURANTE - BACKEND DO FLOW (DATA EXCHANGE).json
│           └── [EMPRESA X] - RESTAURANTE - LIMITES CARDAPIO.md       (doc)
│
├── COMUM/                             ← compartilhado por TODAS as empresas
│   ├── odoo/
│   │   └── ODOO - DOC DAS APIS DISPONIVEIS (Swagger).json   (referência da API)
│   ├── n8n/
│   │   └── ODOO - CALLBACK STATUS PEDIDO.json               (callback de status)
│   └── postgres/
│       └── wa_session.sql                                   (tabela de sessão)
│
└── README.md
```

Convenção de nomes: **`[EMPRESA X] - ...`** marca o que é específico da empresa;
**`ODOO - ...`** / pasta `COMUM/` marca o que é universal. As subpastas `meta/`, `n8n/`,
`odoo/`, `postgres/` dizem **de qual plataforma** é cada arquivo.

---

## 4. Onboarding de uma nova empresa parceira

Quando fechamos com uma empresa nova (ex.: "Empresa Y"):

1. **Associar-se à BM da empresa** na Meta (como parceiro) e ter acesso ao App + WABA(s) + número(s).
2. **Duplicar a pasta** `empresas/EMPRESA X/` → `empresas/EMPRESA Y/` e renomear os arquivos (`[EMPRESA Y] - ...`).
3. **Importar os workflows** (`*.json` de cada pasta `n8n/`) no n8n.
4. **Configurar o webhook na Meta:** apontar o App para a URL do nó *Whatsapp Webhook*
   (`https://<n8n>/webhook/<id>`). A Meta faz uma verificação **GET** (o fluxo responde o
   `hub.challenge`); depois as mensagens chegam por **POST**.
5. **Preencher os placeholders `*_TROCAR`** no WEBHOOK META (ver tabela abaixo).
6. **Publicar o Flow** (arquivo de `meta/`) na Meta e pegar o `flow_id`.
7. **Configurar o FLUXO PRINCIPAL e o BACKEND DO FLOW** (token da Cloud API, `flow_id`,
   chave privada do Flow e credenciais do Odoo da empresa).
8. **Rodar `wa_session.sql` uma vez** no Postgres do n8n (só na primeira empresa — a tabela
   é única e serve todas) e apontar as credenciais Postgres dos nós de sessão.

### Placeholders de configuração

**WEBHOOK META** (`EMPRESA X/n8n/...`):

| Placeholder | Onde achar |
|-------------|-----------|
| `WABA_ID_*_TROCAR` | ID de cada WABA (`entry[0].id` que a Meta manda no webhook). |
| `PHONE_NUMBER_ID_*_TROCAR` | ID de cada número (em *Configurações da API* na Meta). |
| `SUB_WF_*_ID_TROCAR` | ID do sub-workflow n8n que recebe aquele número (ex.: o FLUXO PRINCIPAL). |

**FLUXO PRINCIPAL** (nó *Config Disparo*) e **BACKEND DO FLOW** (nó *Config Local*):

| Variável | O que é |
|----------|---------|
| `WA_TOKEN` | Token da WhatsApp Cloud API (para enviar mensagens). |
| `FLOW_ID` / `FLOW_MODE` / `FLOW_CTA` | Identidade e modo do Flow publicado na Meta. |
| `FLOW_PRIVATE_KEY` | Chave privada RSA (PEM) do Flow — usada para descriptografar o *data exchange*. |
| `ODOO_BASE_URL` / `ODOO_AUTH_URL` | Host do Odoo e endpoint de autenticação. |
| `ODOO_DATABASE` / `ODOO_API_KEY` / `ODOO_API_SECRET` | Credenciais Odoo da empresa. |
| `ODOO_COMPANY_ID` / `ODOO_POS_CONFIG_ID` | Empresa e ponto de venda (POS) no Odoo. |

---

## 5. Roteamento é flexível: restaurante é só um exemplo

O **WEBHOOK META** não sabe nada de "restaurante" — ele só descobre **de qual WABA e de qual
número** veio a mensagem e chama o **sub-workflow** que estiver configurado para aquele número.

Ou seja, cada número pode apontar para um fluxo diferente:

```
WEBHOOK META
   ├── Filtro 1 (WABA)
   │     ├── WABA "Cantina"   → Filtro 2 (número) → FLUXO PRINCIPAL (restaurante / pedidos)
   │     │                                        └→ (poderia ter: marketing, reservas, ...)
   │     └── WABA "Clínica"   → Filtro 2 (número) → AGENDAMENTO  (outro fluxo)
   └── WABA/Número não mapeado → log/alerta (ponto único para cadastrar número novo)
```

Hoje o exemplo entregue é o **restaurante**, mas o mesmo webhook pode direcionar para
**qualquer outro fluxo** (agendamento de clínica, marketing, reservas...). Para adicionar um:
crie o sub-workflow, adicione a saída no *Filtro 2* e cole o ID dele no nó `executeWorkflow`.

---

## 6. Sobre o Odoo

O Odoo é a fonte da verdade (catálogo, clientes, pedidos). Para consumir **qualquer** API:

1. **Autenticar uma vez por execução:** `POST {ODOO_AUTH_URL}` com os headers
   `X-Odoo-Database`, `api-key`, `api-secret` → devolve um token.
2. **Usar o token como `Bearer`** nas chamadas da API POS (prefixo `/lym/pos/...`),
   ex.: listar produtos, buscar cliente por telefone, criar/consultar pedido.

A spec completa das APIs disponíveis está em
`COMUM/odoo/ODOO - DOC DAS APIS DISPONIVEIS (Swagger).json` — é o JSON exportado do Swagger,
usado como referência para montar as chamadas no n8n.

Quando o status de um pedido muda no Odoo, o Odoo chama o **ODOO CALLBACK** (um webhook n8n
universal, em `COMUM/n8n/`), que então **notifica o cliente** no WhatsApp.
