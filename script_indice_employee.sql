-- =====================================================================
-- indices_e_consultas_company.sql (MySQL 8.0 / InnoDB)
-- Objetivo: Criar índices necessários e responder às consultas do cenário
-- =====================================================================

-- ----------------------------
-- ÍNDICES (apenas os relevantes às consultas)
-- ----------------------------

-- 1) employee(department_id, nome)
-- Motivos:
--  - JOIN e GROUP BY por department_id (contagem por departamento)
--  - ORDER BY nome dentro do departamento (relação empregados por depto)
--  - Índice composto aproveita a propriedade de prefixo à esquerda
--    (serve equality join em department_id e ordenação por nome)
ALTER TABLE employee
  ADD INDEX idx_employee_dept_nome (department_id, nome);

-- 2) department_location(city, department_id)
-- Motivos:
--  - Agrupamento/relato por cidade ("departamentos por cidade")
--  - JOIN por department_id para trazer o nome do departamento
--  - city primeiro (para agrupar/filtrar), department_id para join
CREATE INDEX idx_deptloc_city_dept
  ON department_location (city, department_id);

-- 3) department(nome) UNIQUE (opcional, integridade + buscas por nome)
-- Motivos:
--  - Evitar nomes duplicados
--  - Acelerar buscas pontuais por nome (quando existirem)
ALTER TABLE department
  ADD UNIQUE KEY uq_department_nome (nome);

-- Observações sobre tipos:
--  - InnoDB usa B-TREE por padrão (ideal para igualdade, range e ORDER BY).
--  - Evitamos índices redundantes e de baixa seletividade.
--  - Ajuste collation/length se usar utf8mb4 em colunas muito longas.

-- =====================================================================
-- CONSULTAS
-- =====================================================================

-- P1) Qual o departamento com maior número de pessoas?
-- Versão simples (apenas o primeiro)
SELECT
  d.id,
  d.nome,
  COUNT(e.id) AS total_funcionarios
FROM department d
JOIN employee e ON e.department_id = d.id
GROUP BY d.id, d.nome
ORDER BY total_funcionarios DESC
LIMIT 1;

-- Versão que retorna empates (se houver)
WITH contagens AS (
  SELECT d.id, d.nome, COUNT(e.id) AS total
  FROM department d
  JOIN employee e ON e.department_id = d.id
  GROUP BY d.id, d.nome
)
SELECT c.*
FROM contagens c
WHERE c.total = (SELECT MAX(total) FROM contagens);

-- P2) Quais são os departamentos por cidade?
-- Lista cada cidade com os departamentos presentes nela
SELECT
  dl.city AS cidade,
  GROUP_CONCAT(DISTINCT d.nome ORDER BY d.nome SEPARATOR ', ') AS departamentos
FROM department_location dl
JOIN department d ON d.id = dl.department_id
GROUP BY dl.city
ORDER BY dl.city;

-- (Opcional) Se quiser a relação linha a linha, sem agregação:
-- SELECT dl.city, d.nome
-- FROM department_location dl
-- JOIN department d ON d.id = dl.department_id
-- ORDER BY dl.city, d.nome;

-- P3) Relação de empregados por departamento
-- Lista empregados ordenados por departamento e nome
SELECT
  d.nome AS departamento,
  e.id   AS empregado_id,
  e.nome AS empregado,
  e.cargo
FROM employee e
JOIN department d ON d.id = e.department_id
ORDER BY d.nome, e.nome;

-- (Opcional) Apenas contagem por departamento:
-- SELECT d.nome, COUNT(*) AS total
-- FROM employee e
-- JOIN department d ON d.id = e.department_id
-- GROUP BY d.nome
-- ORDER BY total DESC;
