# Limites do Cardápio

Limites da tela de cardápio do pedido por WhatsApp.

## Os limites

- **Até 12 categorias**
- **Até 20 produtos por categoria**
- **Até 20 itens diferentes por pedido**

## O que acontece na prática

- Tem **menos** que isso? Funciona normal — o que sobra fica escondido.
- Tem **mais** que isso? O excedente **não aparece**, e o sistema **avisa** que cortou.

## Como saber se cortou algo

Quando passa de algum limite, aparece um aviso:

- **Na tela**, durante o teste. Exemplo:
  *"Aviso: 15 categorias no total, cortou 3"*
- **No n8n**, na execução do fluxo (para o operador conferir).

## Dá para aumentar?

- **Categorias (12)** e **itens por pedido (20)**: sim, dá para aumentar.
- **20 produtos por categoria**: não. É um limite do próprio WhatsApp.