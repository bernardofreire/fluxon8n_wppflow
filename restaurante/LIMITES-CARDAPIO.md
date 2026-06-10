# Limites da tela de Cardápio (WhatsApp Flow)

Documento de referência dos limites usados na tela **PRODUCTS** (cardápio) e nas telas
ligadas a ela no fluxo de pedido do restaurante.

> Por que existem limites: o WhatsApp Flow tem **layout fixo** (sem repetição dinâmica de
> componentes). Cada categoria e cada item de quantidade é um componente **pré-definido** no
> Flow JSON. O endpoint do n8n apenas **mostra ou oculta** esses componentes conforme os
> dados da empresa — ele não cria novos. Por isso há um teto.

## Resumo dos limites

| O que | Limite | Tipo | Onde é definido |
|---|---:|---|---|
| **Categorias** na tela de cardápio | **12** | Configurável | slots `cat_1..cat_12` no Flow JSON + `MAX_CATS` no nó `Monta PRODUCTS` |
| **Produtos por categoria** | **20** | 🔒 Rígido (Meta) | limite do componente `CheckboxGroup` |
| **Itens distintos no carrinho** (tela de quantidades) | **20** | Configurável | slots `slot_1..slot_20` no Flow JSON + `MAX_SLOTS` nos nós `Monta QUANTITIES`/`Monta DELIVERY` |
| **Quantidade por item** | **1 a 10** | Configurável | opções fixas do `Dropdown` (`data-source`) |
| **Tamanho do nome da categoria** (label) | **30 chars** | Boa prática | cortado em `Monta PRODUCTS` |
| **Tamanho do nome do produto** no cardápio | **30 chars** | 🔒 Rígido (Meta) | título da opção do `CheckboxGroup` (≤30) |
| **Tamanho do nome do produto** na tela de quantidade | **20 chars** | 🔒 Rígido (Meta) | label do `Dropdown` (≤20) |

- **Configurável** = dá para aumentar (até o limite de componentes por tela da Meta), mexendo
  no Flow JSON e na constante correspondente no endpoint.
- **Rígido (Meta)** = não dá para ultrapassar mantendo este desenho de tela.

## Comportamento por cenário

- **Menos** categorias/produtos que o máximo → os slots não usados ficam **ocultos
  automaticamente**. Nada a fazer.
- **Mais** que o máximo → o excedente é **cortado** (não aparece) e o sistema **avisa** (ver
  abaixo). Os cortes seguem a ordem em que a API do Odoo retorna os dados.

## Detecção de estouro (quando corta algo)

Quando alguma empresa passa de algum limite, o corte é sinalizado em **dois lugares**:

1. **Na própria tela** (útil em teste): um `TextCaption` de aviso aparece no topo de PRODUCTS
   / QUANTITIES, só quando houve corte. Ex.:
   `Aviso (corte): Categorias: 15 no total, cortou 3 | Categoria "Bebidas": 27 itens, cortou 7`
2. **Nas execuções do n8n** (controle do operador):
   - O nó `Monta PRODUCTS` / `Monta QUANTITIES` sai com o campo **`_warnings`** (lista dos cortes).
   - Um **`console.log`** (`[FLOW PRODUCTS overflow] ...`) nos logs do n8n.

## Como alterar um limite configurável

Os limites configuráveis vivem em **dois lugares que precisam casar**:

1. **Flow JSON** (`flow-restaurante.json`): quantidade de slots/componentes (`cat_N`, `slot_N`).
2. **Endpoint** (`AURORA - Restaurante - Flow Endpoint.json`): as constantes `MAX_CATS` /
   `MAX_SLOTS` nos nós `Monta PRODUCTS`, `Monta QUANTITIES` e `Monta DELIVERY`.

Ambos os arquivos são gerados por script — alterar a constante no gerador e regenerar mantém
os dois em sincronia.

### Limite que NÃO dá para mudar
**20 produtos por categoria** é limite rígido do `CheckboxGroup` da Meta. Para categorias com
mais de 20 itens, seria preciso mudar o desenho (ex.: subcategorias ou navegação por categoria
com paginação).

## Telas do fluxo (contexto)

`PRODUCTS` (cardápio) → `QUANTITIES` (quantidades) → `DELIVERY` (entrega) → `SUMMARY` (resumo)
→ `SUCCESS`.

Os limites deste documento se aplicam às duas primeiras telas (cardápio e quantidades), que são
as que listam produtos.
