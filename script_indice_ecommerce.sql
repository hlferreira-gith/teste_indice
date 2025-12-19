-- =====================================================================
-- UNIVERSIDADE - DDL mínimo + Procedures CRUD com controle p_operacao
-- =====================================================================

CREATE DATABASE IF NOT EXISTS universidade_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE universidade_db;

-- Tabelas básicas
CREATE TABLE IF NOT EXISTS aluno (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  ativo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS curso (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL UNIQUE,
  carga_horaria INT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS matricula (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  aluno_id BIGINT NOT NULL,
  curso_id BIGINT NOT NULL,
  data DATE NOT NULL,
  status ENUM('ATIVA','TRANCADA','CANCELADA','CONCLUIDA') NOT NULL DEFAULT 'ATIVA',
  UNIQUE (aluno_id, curso_id),
  CONSTRAINT fk_mat_aluno FOREIGN KEY (aluno_id) REFERENCES aluno(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mat_curso FOREIGN KEY (curso_id) REFERENCES curso(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

-- Procedure: Aluno
DROP PROCEDURE IF EXISTS sp_aluno_gerenciar $$
CREATE PROCEDURE sp_aluno_gerenciar(
  IN p_operacao INT,         -- 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
  IN p_id BIGINT,
  IN p_nome VARCHAR(150),
  IN p_email VARCHAR(150),
  IN p_ativo TINYINT
)
BEGIN
  IF p_operacao = 1 THEN
    -- SELECT
    IF p_id IS NULL THEN
      SELECT * FROM aluno ORDER BY nome;
    ELSE
      SELECT * FROM aluno WHERE id = p_id;
    END IF;

  ELSEIF p_operacao = 2 THEN
    -- INSERT
    IF p_nome IS NULL OR p_email IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: nome e email são obrigatórios';
    END IF;

    IF EXISTS (SELECT 1 FROM aluno WHERE email = p_email) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: email já cadastrado';
    END IF;

    INSERT INTO aluno (nome, email, ativo)
    VALUES (p_nome, p_email, COALESCE(p_ativo, 1));

    SELECT LAST_INSERT_ID() AS novo_id;

  ELSEIF p_operacao = 3 THEN
    -- UPDATE
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: p_id é obrigatório';
    END IF;

    IF p_email IS NOT NULL AND EXISTS (
      SELECT 1 FROM aluno WHERE email = p_email AND id <> p_id
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: email em uso por outro aluno';
    END IF;

    UPDATE aluno
       SET nome  = COALESCE(p_nome, nome),
           email = COALESCE(p_email, email),
           ativo = COALESCE(p_ativo, ativo)
     WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSEIF p_operacao = 4 THEN
    -- DELETE
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DELETE: p_id é obrigatório';
    END IF;

    DELETE FROM aluno WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE';
  END IF;
END $$

-- Procedure: Curso
DROP PROCEDURE IF EXISTS sp_curso_gerenciar $$
CREATE PROCEDURE sp_curso_gerenciar(
  IN p_operacao INT,
  IN p_id BIGINT,
  IN p_nome VARCHAR(150),
  IN p_carga_horaria INT
)
BEGIN
  IF p_operacao = 1 THEN
    IF p_id IS NULL THEN
      SELECT * FROM curso ORDER BY nome;
    ELSE
      SELECT * FROM curso WHERE id = p_id;
    END IF;

  ELSEIF p_operacao = 2 THEN
    IF p_nome IS NULL OR p_carga_horaria IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: nome e carga_horaria são obrigatórios';
    END IF;

    IF EXISTS (SELECT 1 FROM curso WHERE nome = p_nome) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: curso já existe';
    END IF;

    INSERT INTO curso (nome, carga_horaria) VALUES (p_nome, p_carga_horaria);
    SELECT LAST_INSERT_ID() AS novo_id;

  ELSEIF p_operacao = 3 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: p_id é obrigatório';
    END IF;

    IF p_nome IS NOT NULL AND EXISTS (
      SELECT 1 FROM curso WHERE nome = p_nome AND id <> p_id
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: nome em uso por outro curso';
    END IF;

    UPDATE curso
       SET nome = COALESCE(p_nome, nome),
           carga_horaria = COALESCE(p_carga_horaria, carga_horaria)
     WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSEIF p_operacao = 4 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DELETE: p_id é obrigatório';
    END IF;

    DELETE FROM curso WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE';
  END IF;
END $$

-- Procedure: Matrícula
DROP PROCEDURE IF EXISTS sp_matricula_gerenciar $$
CREATE PROCEDURE sp_matricula_gerenciar(
  IN p_operacao INT,
  IN p_id BIGINT,
  IN p_aluno_id BIGINT,
  IN p_curso_id BIGINT,
  IN p_data DATE,
  IN p_status ENUM('ATIVA','TRANCADA','CANCELADA','CONCLUIDA)
)
BEGIN
  IF p_operacao = 1 THEN
    IF p_id IS NULL THEN
      SELECT m.*, a.nome AS aluno, c.nome AS curso
      FROM matricula m
      JOIN aluno a ON a.id = m.aluno_id
      JOIN curso c ON c.id = m.curso_id
      ORDER BY m.data DESC;
    ELSE
      SELECT m.*, a.nome AS aluno, c.nome AS curso
      FROM matricula m
      JOIN aluno a ON a.id = m.aluno_id
      JOIN curso c ON c.id = m.curso_id
      WHERE m.id = p_id;
    END IF;

  ELSEIF p_operacao = 2 THEN
    IF p_aluno_id IS NULL OR p_curso_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: aluno_id e curso_id são obrigatórios';
    END IF;

    IF EXISTS (SELECT 1 FROM matricula WHERE aluno_id = p_aluno_id AND curso_id = p_curso_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: aluno já matriculado neste curso';
    END IF;

    INSERT INTO matricula (aluno_id, curso_id, data, status)
    VALUES (p_aluno_id, p_curso_id, COALESCE(p_data, CURDATE()), COALESCE(p_status, 'ATIVA'));

    SELECT LAST_INSERT_ID() AS novo_id;

  ELSEIF p_operacao = 3 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: p_id é obrigatório';
    END IF;

    UPDATE matricula
       SET aluno_id = COALESCE(p_aluno_id, aluno_id),
           curso_id = COALESCE(p_curso_id, curso_id),
           data     = COALESCE(p_data, data),
           status   = COALESCE(p_status, status)
     WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSEIF p_operacao = 4 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DELETE: p_id é obrigatório';
    END IF;

    DELETE FROM matricula WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE';
  END IF;
END $$

DELIMITER ;

-- =========================
-- EXEMPLOS DE CHAMADA
-- =========================
-- Cursos
CALL sp_curso_gerenciar(2, NULL, 'Banco de Dados', 60);
CALL sp_curso_gerenciar(2, NULL, 'Estruturas de Dados', 80);
CALL sp_curso_gerenciar(1, NULL, NULL, NULL);

-- Alunos
CALL sp_aluno_gerenciar(2, NULL, 'Maria Alves', 'maria@uni.com', 1);
CALL sp_aluno_gerenciar(2, NULL, 'João Souza', 'joao@uni.com', 1);
CALL sp_aluno_gerenciar(1, NULL, NULL, NULL, NULL);

-- Matrícula (pegar ids conforme inseridos)
-- Exemplo: matricular Maria (id 1) em Banco de Dados (id 1)
CALL sp_matricula_gerenciar(2, NULL, 1, 1, CURDATE(), 'ATIVA');
CALL sp_matricula_gerenciar(1, NULL, NULL, NULL, NULL, NULL);

-- Atualizar aluno
CALL sp_aluno_gerenciar(3, 1, 'Maria A. Alves', NULL, NULL);

-- Deletar curso (falhará se houver matrícula usando RESTRICT)
-- CALL sp_curso_gerenciar(4, 1, NULL, NULL);
