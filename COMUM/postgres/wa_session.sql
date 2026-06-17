-- Sessao de conversa do WhatsApp (controle de contexto do FLUXO PRINCIPAL).
-- Uma unica tabela central serve TODAS as copias por BM: a PK (channel_id, phone)
-- usa o phone_number_id como namespace, entao numeros/BMs diferentes nunca colidem.
--
-- Rode uma vez no Postgres que o n8n usa, e aponte a credencial Postgres dos nos
-- "Sessao Claim" e "Sessao Save" para esse banco.

CREATE TABLE IF NOT EXISTS wa_session (
  channel_id    text        NOT NULL,                 -- phone_number_id (o numero/BM)
  phone         text        NOT NULL,                 -- telefone do cliente (so digitos)
  state         text        NOT NULL DEFAULT 'IDLE',  -- IDLE | FLOW_OPEN | MENU | AWAITING_PAYMENT | ORDER_PLACED | HUMAN
  valid_actions jsonb       NOT NULL DEFAULT '[]',    -- ids de botao aceitos na tela atual
  last_wamid    text,                                 -- ultimo message.id processado (idempotencia)
  context       jsonb       NOT NULL DEFAULT '{}',    -- ex.: { "last_flow_token": "...", "open_order_id": 58 }
  updated_at    timestamptz NOT NULL DEFAULT now(),   -- ultima interacao (base do TTL de 45 min)
  PRIMARY KEY (channel_id, phone)
);

-- Limpeza opcional de sessoes muito antigas (rode por cron se quiser; nao e obrigatorio,
-- o TTL ja e aplicado em memoria pelo no "Guarda de Contexto").
-- DELETE FROM wa_session WHERE updated_at < now() - interval '7 days';
