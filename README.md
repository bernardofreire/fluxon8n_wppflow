# Fluxo n8n · WhatsApp Webhook — Grupo Aurora

Workflow principal do n8n que recebe o webhook do WhatsApp Cloud API de **uma URL única por BM** (Business Manager) e roteia as mensagens em 2 níveis até os sub-workflows de cada unidade.

## Arquitetura

```
App único (1 URL de webhook)
        │
Workflow principal (recebe tudo)
        │
Filtro 1 · WABA  ........ por entry[0].id (waba_id)
        ├── Restaurante / Cantina
        │       └── Filtro 2 · phone_number_id → sub-workflows (Reservas/Pedidos, Marketing)
        └── Clínica
                └── Filtro 2 · phone_number_id → sub-workflow (Agendamento)
```

- **GET** (verificação Meta): responde `hub.challenge`.
- **POST** (mensagens): responde **200 OK imediato** (ACK), depois filtra/extrai a mensagem real (descarta `statuses`/`system`) e roteia por `waba_id` → `phone_number_id`.
- Saída de fallback única (**WABA/Número não mapeado**) para log/alerta ao cadastrar número novo.

## Como usar

1. Importe `GRUPO AURORA - WEBHOOK.json` no n8n.
2. Substitua os placeholders `*_TROCAR` pelos IDs reais (WABA IDs, phone_number_ids e IDs dos sub-workflows).
3. Configure essa URL de webhook na BM do Meta.
