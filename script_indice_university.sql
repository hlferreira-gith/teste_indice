-- =====================================================================
-- E-COMMERCE - DDL mínimo + Procedures CRUD com controle p_operacao
-- =====================================================================

CREATE DATABASE IF NOT EXISTS ecommerce_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE ecommerce_db;

-- Tabelas básicas
CREATE TABLE IF NOT EXISTS cliente (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('PF','PJ') NOT NULL,
  nome VARCHAR(150) NOT NULL,
  cpf_cnpj VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(150),
  telefone VARCHAR(30),
  ativo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS produto (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  sku VARCHAR(50) NOT NULL UNIQUE,
  preco DECIMAL(12,2) NOT NULL,
  estoque INT NOT NULL DEFAULT 0,
  ativo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedido (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cliente_id BIGINT NOT NULL,
  data DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('ABERTO','PAGO','ENVIADO','CANCELADO') NOT NULL DEFAULT 'ABERTO',
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedido_item (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  pedido_id BIGINT NOT NULL,
  produto_id BIGINT NOT NULL,
  qtde INT NOT NULL,
  preco_unitario DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_item_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_item_produto FOREIGN KEY (produto_id) REFERENCES produto(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

-- Procedure: Cliente
DROP PROCEDURE IF EXISTS sp_cliente_gerenciar $$
CREATE PROCEDURE sp_cliente_gerenciar(
  IN p_operacao INT,             -- 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
  IN p_id BIGINT,
  IN p_tipo ENUM('PF','PJ'),
  IN p_nome VARCHAR(150),
  IN p_cpf_cnpj VARCHAR(20),
  IN p_email VARCHAR(150),
  IN p_telefone VARCHAR(30),
  IN p_ativo TINYINT
)
BEGIN
  IF p_operacao = 1 THEN
    IF p_id IS NULL THEN
      SELECT * FROM cliente ORDER BY nome;
    ELSE
      SELECT * FROM cliente WHERE id = p_id;
    END IF;

  ELSEIF p_operacao = 2 THEN
    IF p_tipo IS NULL OR p_nome IS NULL OR p_cpf_cnpj IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: tipo, nome e cpf_cnpj são obrigatórios';
    END IF;

    IF EXISTS (SELECT 1 FROM cliente WHERE cpf_cnpj = p_cpf_cnpj) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: cpf_cnpj já cadastrado';
    END IF;

    INSERT INTO cliente (tipo, nome, cpf_cnpj, email, telefone, ativo)
    VALUES (p_tipo, p_nome, p_cpf_cnpj, p_email, p_telefone, COALESCE(p_ativo,1));
    SELECT LAST_INSERT_ID() AS novo_id;

  ELSEIF p_operacao = 3 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: p_id é obrigatório';
    END IF;

    IF p_cpf_cnpj IS NOT NULL AND EXISTS (
      SELECT 1 FROM cliente WHERE cpf_cnpj = p_cpf_cnpj AND id <> p_id
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: cpf_cnpj em uso por outro cliente';
    END IF;

    UPDATE cliente
       SET tipo     = COALESCE(p_tipo, tipo),
           nome     = COALESCE(p_nome, nome),
           cpf_cnpj = COALESCE(p_cpf_cnpj, cpf_cnpj),
           email    = COALESCE(p_email, email),
           telefone = COALESCE(p_telefone, telefone),
           ativo    = COALESCE(p_ativo, ativo)
     WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSEIF p_operacao = 4 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DELETE: p_id é obrigatório';
    END IF;

    DELETE FROM cliente WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE';
  END IF;
END $$

-- Procedure: Produto
DROP PROCEDURE IF EXISTS sp_produto_gerenciar $$
CREATE PROCEDURE sp_produto_gerenciar(
  IN p_operacao INT,         -- 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
  IN p_id BIGINT,
  IN p_nome VARCHAR(150),
  IN p_sku VARCHAR(50),
  IN p_preco DECIMAL(12,2),
  IN p_estoque INT,
  IN p_ativo TINYINT
)
BEGIN
  IF p_operacao = 1 THEN
    IF p_id IS NULL THEN
      SELECT * FROM produto ORDER BY nome;
    ELSE
      SELECT * FROM produto WHERE id = p_id;
    END IF;

  ELSEIF p_operacao = 2 THEN
    IF p_nome IS NULL OR p_sku IS NULL OR p_preco IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: nome, sku e preco são obrigatórios';
    END IF;

    IF p_preco < 0 OR COALESCE(p_estoque,0) < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: preco/estoque não podem ser negativos';
    END IF;

    IF EXISTS (SELECT 1 FROM produto WHERE sku = p_sku) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT: sku já cadastrado';
    END IF;

    INSERT INTO produto (nome, sku, preco, estoque, ativo)
    VALUES (p_nome, p_sku, p_preco, COALESCE(p_estoque,0), COALESCE(p_ativo,1));
    SELECT LAST_INSERT_ID() AS novo_id;

  ELSEIF p_operacao = 3 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: p_id é obrigatório';
    END IF;

    IF p_sku IS NOT NULL AND EXISTS (
      SELECT 1 FROM produto WHERE sku = p_sku AND id <> p_id
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: sku em uso por outro produto';
    END IF;

    IF p_preco IS NOT NULL AND p_preco < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: preco não pode ser negativo';
    END IF;

    IF p_estoque IS NOT NULL AND p_estoque < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE: estoque não pode ser negativo';
    END IF;

    UPDATE produto
       SET nome    = COALESCE(p_nome, nome),
           sku     = COALESCE(p_sku, sku),
           preco   = COALESCE(p_preco, preco),
           estoque = COALESCE(p_estoque, estoque),
           ativo   = COALESCE(p_ativo, ativo)
     WHERE id = p_id;

    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSEIF p_operacao = 4 THEN
    IF p_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DELETE: p_id é obrigatório';
    END IF;

    DELETE FROM produto WHERE id = p_id;
    SELECT ROW_COUNT() AS linhas_afetadas;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE';
  END IF;
END $$

DELIMITER ;

-- =========================
-- EXEMPLOS DE CHAMADA
-- =========================
-- Clientes
CALL sp_cliente_gerenciar(2, NULL, 'PF', 'Ana Paula', '123.456.789-00', 'ana@ex.com', '(61)9999-0001', 1);
CALL sp_cliente_gerenciar(2, NULL, 'PJ', 'Loja XPTO Ltda', '12.345.678/0001-99', 'contato@xpto.com', '(11)4002-8922', 1);
CALL sp_cliente_gerenciar(1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Produtos
CALL sp_produto_gerenciar(2, NULL, 'Mouse Gamer', 'SKU-MOUSE-01', 99.90, 50, 1);
CALL sp_produto_gerenciar(2, NULL, 'Teclado Mecânico', 'SKU-TECLADO-01', 299.00, 20, 1);
CALL sp_produto_gerenciar(1, NULL, NULL, NULL, NULL, NULL, NULL);

-- Atualização
CALL sp_cliente_gerenciar(3, 1, NULL, 'Ana P. Silva', NULL, 'ana.silva@ex.com', NULL, NULL);
CALL sp_produto_gerenciar(3, 1, NULL, NULL, 109.90, 60, NULL);

-- Exclusão
-- CALL sp_cliente_gerenciar(4, 2, NULL, NULL, NULL, NULL, NULL, NULL);
-- CALL sp_produto_gerenciar(4, 2, NULL, NULL, NULL, NULL, NULL);
