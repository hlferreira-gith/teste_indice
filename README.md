# Company – Índices e Consultas (Parte 1)

Este repositório contém o script de criação de índices e as consultas SQL para o cenário “company”, respondendo às perguntas do desafio:

1) Qual o departamento com maior número de pessoas?
2) Quais são os departamentos por cidade?
3) Relação de empregados por departamento

## Esquema assumido
- department(id PK, nome UNIQUE)
- employee(id PK, nome, cargo, department_id FK -> department.id)
- department_location(department_id FK -> department.id, city)

Adapte os nomes/colunas conforme seu banco.

## Índices criados e justificativa

- employee(department_id, nome)
  - Motivos:
    - JOIN/GROUP BY por department_id (contagem por departamento)
    - ORDER BY nome por departamento (relação de empregados)
    - Índice composto (B-Tree) atende igualdade em department_id e ordenação por nome
  - Benefício direto nas P1 e P3

- department_location(city, department_id)
  - Motivos:
    - Relato/agrupamento por cidade (P2)
    - JOIN por department_id para obter o nome do departamento
    - city primeiro pela seletividade e agrupamento
  - Benefício direto na P2

- department(nome) UNIQUE (opcional)
  - Motivos:
    - Integridade: evita nomes duplicados
    - Acelera buscas pontuais por nome (quando existirem)
  - Não é crítico para as consultas acima, mas é boa prática

Obs.:
- InnoDB usa B-Tree por padrão (adequado para igualdade, range e ORDER BY).
- Evitamos índices redundantes e colunas de baixa seletividade.
- Reavalie após medir com EXPLAIN/ANALYZE em seu volume real de dados.

## Como executar

1) Rode os índices e consultas (MySQL 8.0):
```bash
mysql -h 127.0.0.1 -u root -p < indices_e_consultas_company.sql
