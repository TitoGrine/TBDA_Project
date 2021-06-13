/*
 * Type Creation
 */
DROP TYPE ucs_t FORCE;
DROP TYPE ocorrencias_t FORCE;
DROP TYPE docentes_t FORCE;
DROP TYPE docentes_ref_t FORCE;
DROP TYPE docentes_ref_tab_t FORCE;
DROP TYPE tiposaula_t FORCE;
DROP TYPE tiposaula_ref_t FORCE;
DROP TYPE tiposaula_ref_tab_t FORCE;
DROP TYPE dsd_t FORCE;
DROP TYPE dsd_tab_t FORCE;

CREATE TYPE ucs_t AS object
(
  codigo     VARCHAR2(9),
  sigla_uc   VARCHAR2(6),
  designacao VARCHAR2(150),
  curso      NUMBER(4),
  -- methods --
  MAP MEMBER FUNCTION get_avg_approval_rate
    RETURN NUMBER
);
/
CREATE TYPE ocorrencias_t AS object
(
  uc             REF ucs_t,
  ano_letivo     VARCHAR2(9),
  periodo        VARCHAR2(2),
  inscritos      NUMBER(38),
  conteudo       VARCHAR2(4000),
  objetivos      VARCHAR2(4000),
  aprovados      NUMBER(38),
  departamento   VARCHAR2(6),
  com_frequencia NUMBER(38)
  /* tipos tiposaula_ref_tab_t to be added later */
);
/
CREATE TYPE docentes_t AS object
(
  nr        NUMBER,
  nome      VARCHAR2(75),
  estado    VARCHAR2(3),
  apelido   VARCHAR2(25),
  proprio   VARCHAR2(25),
  categoria NUMBER,
  sigla     VARCHAR2(8),
  /* aulas dsd_tab_t to be added later */
);
/
CREATE TYPE docentes_ref_t AS object
(
  docente REF docentes_t
);
/
CREATE TYPE docentes_ref_tab_t AS TABLE OF docentes_ref_t;
/
CREATE TYPE tiposaula_t AS object
(
  id          NUMBER(10),
  tipo        VARCHAR2(2),
  horas_turno NUMBER(4,2),
  n_aulas     NUMBER,
  turnos      NUMBER(4,2),
  ocorrencia  REF ocorrencias_t,
  docentes    docentes_ref_tab_t,
  -- methods--
  MAP MEMBER FUNCTION class_hours
    RETURN NUMBER,
  STATIC FUNCTION total_hours(v_curso number, v_periodo varchar2, v_ano_letivo varchar2)
    RETURN NUMBER
);
/
CREATE TYPE tiposaula_ref_t AS object
(
  tipo REF tiposaula_t
);
/
CREATE TYPE tiposaula_ref_tab_t AS TABLE OF tiposaula_ref_t;
/
CREATE TYPE dsd_t AS object
(
  aula  REF tiposaula_t,
  horas NUMBER(4,2),
  ordem NUMBER,
  fator NUMBER(3,2)
);
/
CREATE TYPE dsd_tab_t AS TABLE OF dsd_t;
/
-- Insert missing fields due to circularity
ALTER TYPE ocorrencias_t ADD attribute
(
  tipos tiposaula_ref_tab_t
) CASCADE;

ALTER TYPE docentes_t ADD attribute
(
  aulas dsd_tab_t
) CASCADE;

/*
 * Table Creation
 */
DROP TABLE docentes CASCADE CONSTRAINTS;
DROP TABLE ocorrencias CASCADE CONSTRAINTS;
DROP TABLE ucs CASCADE CONSTRAINTS;
DROP TABLE tiposaula CASCADE CONSTRAINTS;

CREATE TABLE ucs OF ucs_t
(
    designacao NOT NULL,
    CONSTRAINT ucs_pk PRIMARY KEY (codigo)
);

CREATE TABLE docentes OF docentes_t
(
    nome   NOT NULL,
    sigla  NOT NULL,
    estado NOT NULL,
    CONSTRAINT docentes_pk PRIMARY KEY (nr)
) nested TABLE aulas store AS aulas_tab;

CREATE TABLE ocorrencias OF ocorrencias_t
(
    uc         NOT NULL,
    ano_letivo NOT NULL,
    periodo    NOT NULL,
    CONSTRAINT ocorrencias_ucs_fk FOREIGN KEY (uc) REFERENCES ucs
) nested TABLE tipos store AS tipos_tab;

CREATE TABLE tiposaula OF tiposaula_t
(
    tipo NOT NULL,
    CONSTRAINT tiposaula_pk PRIMARY KEY (id),
    CONSTRAINT tiposaula_ocorrencias_fk FOREIGN KEY (ocorrencia) REFERENCES ocorrencias
) nested TABLE docentes store AS docentes_tab;

/*
 * Populate
 */
-- ucs
INSERT INTO ucs
SELECT codigo,
       sigla_uc,
       designacao,
       curso
FROM   xucs; 

-- ocorrencias
INSERT INTO ocorrencias
SELECT ref(u),
       ano_letivo,
       periodo,
       inscritos,
       conteudo,
       objetivos,
       aprovados,
       departamento,
       com_frequencia,
       tiposaula_ref_tab_t() AS tipos
FROM   xocorrencias,
       ucs u
WHERE  u.codigo = xocorrencias.codigo;  

-- docentes
INSERT INTO docentes
SELECT nr,
       nome,
       estado,
       apelido,
       proprio,
       categoria,
       sigla,
       dsd_tab_t() AS aulas
FROM   xdocentes;  

-- tipos aula
DECLARE
  CURSOR tiposaula_it IS
    SELECT id,
           tipo,
           horas_turno,
           n_aulas,
           turnos,
           ref(o) AS ocorrencia
    FROM   xtiposaula
    join   ocorrencias o
    ON     xtiposaula.ano_letivo = o.ano_letivo
    AND    xtiposaula.periodo = o.periodo
    AND    xtiposaula.codigo = o.uc.codigo;

    tipos_ref REF TIPOSAULA_T;
BEGIN
  FOR tiposaula_rec IN tiposaula_it
  LOOP
    INSERT INTO tiposaula t VALUES
                (
                    tiposaula_rec.id,
                    tiposaula_rec.tipo,
                    tiposaula_rec.horas_turno,
                    tiposaula_rec.n_aulas,
                    tiposaula_rec.turnos,
                    tiposaula_rec.ocorrencia,
                    docentes_ref_tab_t()
                )
    returning   ref(t)
    INTO        tipos_ref;
    
    INSERT INTO table
                (
                    SELECT tipos
                    FROM   ocorrencias o
                    WHERE  tiposaula_rec.ocorrencia = ref(o)
                )
                VALUES
                (
                    tiposaula_ref_t(tipos_ref)
                );
  END LOOP;

  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END; 

-- docentes - dsd - tiposaula
DECLARE
  CURSOR dsd_it IS
    SELECT nr,
           id,
           horas,
           ordem,
           fator
    FROM   xdsd;

  docente_ref REF DOCENTES_T;
  tiposaula_ref REF TIPOSAULA_T;
BEGIN
  FOR dsd_rec IN dsd_it
  LOOP
    SELECT ref(d)
    INTO   docente_ref
    FROM   docentes d
    WHERE  d.nr = dsd_rec.nr;

    SELECT ref(t)
    INTO   tiposaula_ref
    FROM   tiposaula t
    WHERE  t.id = dsd_rec.id;

    INSERT INTO table
                (
                    SELECT docentes
                    FROM   tiposaula t
                    WHERE  t.id = dsd_rec.id
                )
                VALUES
                (
                    docente_ref
                );
    
    INSERT INTO table
                (
                    SELECT aulas
                    FROM   docentes d
                    WHERE  d.nr = dsd_rec.nr
                )
                VALUES
                (
                    tiposaula_ref,
                    dsd_rec.horas,
                    dsd_rec.ordem,
                    dsd_rec.fator
                );
  END LOOP;

  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END;

/*
 * Object Methods and Functions
 */
CREATE OR replace TYPE BODY tiposaula_t AS
    -- class_hours
    MAP MEMBER FUNCTION class_hours
      RETURN NUMBER
    IS
    BEGIN
      RETURN horas_turno * turnos;
    END class_hours;
    
    -- total_hours
    STATIC FUNCTION total_hours(v_curso      NUMBER,
                              v_periodo    VARCHAR2,
                              v_ano_letivo VARCHAR2)
      RETURN NUMBER
    IS
    v_total NUMBER;
    BEGIN
      SELECT COALESCE(SUM(t.class_hours()), 0) AS horas_semanais
      INTO   v_total
      FROM   tiposaula t
      WHERE  t.ocorrencia.uc.curso = v_curso
             AND t.ocorrencia.periodo = v_periodo
             AND t.ocorrencia.ano_letivo = v_ano_letivo;
      RETURN v_total;
    END total_hours;
END;

CREATE OR REPLACE TYPE BODY ucs_t AS
    MAP MEMBER FUNCTION get_avg_approval_rate
      RETURN NUMBER
    IS
      approval_rate NUMBER;
    BEGIN
      SELECT avg(o.aprovados/o.inscritos)
      INTO   approval_rate
      FROM   ocorrencia o
      WHERE  o.uc = ref(self);
      
      RETURN approval_rate;
    END get_avg_approval_rate;
END;

/*
 * Question a)
 */
-- starting with the ocorrencias table
SELECT o.uc.curso                AS curso,
       o.ano_letivo              AS ano_Letivo,
       t.tipo.tipo               AS tipo,
       SUM(t.tipo.class_hours()) AS horas
FROM   ocorrencias o,
       TABLE(o.tipos) t
WHERE  o.uc.curso = 233
       AND o.ano_letivo = '2004/2005'
GROUP  BY t.tipo.tipo,
          ano_letivo,
          o.uc.curso;

-- starting with the tiposaula table
SELECT t.ocorrencia.uc.curso    AS curso,
       t.ocorrencia.ano_letivo  AS ano_Letivo,
       t.tipo                   AS tipo,
       SUM(t.class_hours())     AS horas
FROM   tiposaula t
WHERE  t.ocorrencia.uc.curso = 233
       AND t.ocorrencia.ano_letivo = '2004/2005'
GROUP  BY t.tipo,
          t.ocorrencia.ano_letivo,
          t.ocorrencia.uc.curso;

/*
 * Question b)
 */
-------------------------------
-- Starting at ocorrencias
SELECT o.uc.codigo               AS codigo,
       SUM(t.tipo.class_hours()) AS total_required,
       SUM(a.horas)              AS service_assigned
FROM   ocorrencias o,
       TABLE(o.tipos) t,
       TABLE(t.tipo.docentes) d,
       TABLE(d.docente.aulas) a
WHERE  o.ano_letivo = '2003/2004'
       AND a.aula = t.tipo
GROUP  BY o.uc.codigo
HAVING SUM(t.tipo.class_hours()) != SUM(a.horas)
ORDER  BY o.uc.codigo;

---------------------------------
-- Starting at tiposaula
SELECT t.ocorrencia.uc.codigo AS codigo,
       SUM(t.class_hours())   AS total_required,
       SUM(a.horas)           AS service_assigned
FROM   tiposaula t,
       TABLE(t.docentes) d,
       TABLE(d.docente.aulas) a
WHERE  t.ocorrencia.ano_letivo = '2003/2004'
       AND a.aula = ref(t)
GROUP  BY t.ocorrencia.uc.codigo
HAVING SUM(t.class_hours()) != SUM(a.horas)
ORDER  BY t.ocorrencia.uc.codigo;

-------------------------------------
-- Starting at docentes
SELECT a.aula.ocorrencia.uc.codigo AS codigo,
       SUM(a.aula.class_hours())   AS total_required,
       SUM(a.horas)                AS service_assigned
FROM   docentes d,
       TABLE(d.aulas) a
WHERE  a.aula.ocorrencia.ano_letivo = '2003/2004'
GROUP  BY a.aula.ocorrencia.uc.codigo
HAVING SUM(a.aula.class_hours()) != SUM(a.horas)
ORDER  BY a.aula.ocorrencia.uc.codigo;

/*
 * Question c)
 */
CREATE OR replace VIEW total_per_type
AS
  SELECT d.docente.nr   AS nr,
         d.docente.nome AS name,
         t.tipo.tipo    AS tipo,
         SUM(a.horas)   AS total_hours
  FROM   ocorrencias o,
         TABLE(o.tipos) t,
         TABLE(t.tipo.docentes) d,
         TABLE(d.docente.aulas) a
  WHERE  o.ano_letivo = '2003/2004'
         AND a.aula = t.tipo
  GROUP  BY t.tipo.tipo,
            d.docente.nr,
            d.docente.nome
  ORDER  BY d.docente.nome;

SELECT nr,
       name,
       total_per_type.tipo,
       total_hours
FROM   (SELECT tipo,
               MAX(total_hours) AS max_hours
        FROM   total_per_type
        GROUP  BY tipo) max_per_type
       JOIN total_per_type
         ON max_per_type.tipo = total_per_type.tipo
WHERE  max_per_type.max_hours = total_per_type.total_hours;

/*
 * Question d)
 */
-- docentes -> ocorrencia
SELECT d.categoria                  AS categoria,
       d.nome                       AS nome,
       a.aula.ocorrencia.ano_letivo AS ano_letivo,
       AVG(a.horas)                 AS media_horas
FROM   docentes d,
       TABLE(d.aulas) a
WHERE  a.aula.ocorrencia.ano_letivo IN ( '2001/2002', '2002/2003', '2003/2004', '2004/2005' )
GROUP  BY d.categoria,
          a.aula.ocorrencia.ano_letivo,
          d.nome
ORDER  BY nome,
          ano_letivo;

-- ocorrencia -> docentes
SELECT d.docente.categoria AS categoria,
       d.docente.nome      AS nome,
       o.ano_letivo        AS ano_letivo,
       AVG(a.horas)        AS media_horas
FROM   ocorrencias o,
       TABLE(o.tipos) t,
       TABLE(t.tipo.docentes) d,
       TABLE(d.docente.aulas) a
WHERE  o.ano_letivo IN ( '2001/2002', '2002/2003', '2003/2004', '2004/2005' )
       AND a.aula = t.tipo
GROUP  BY d.docente.categoria,
          o.ano_letivo,
          d.docente.nome
ORDER  BY nome,
          ano_letivo;

/*
 * Question e)
 */
SELECT t.ocorrencia.uc.curso AS curso,
       t.ocorrencia.periodo  AS semestre,
       SUM(t.horas_turno)    AS horas_semanais
FROM   tiposaula t
WHERE  t.ocorrencia.periodo IN ( '1S', '2S' )
       AND t.ocorrencia.ano_letivo = (-- this may be an argument (2009/2010)
                                     SELECT MAX(o.ano_letivo)
                                     FROM   ocorrencias o)
GROUP  BY t.ocorrencia.uc.curso,
          t.ocorrencia.periodo
ORDER  BY t.ocorrencia.uc.curso,
          t.ocorrencia.periodo;

----------------------------------
-- using static function in tiposaula_t
SELECT t.ocorrencia.uc.curso    AS curso,
       t.ocorrencia.periodo     AS semestre,
       tiposaula_t.total_hours(t.ocorrencia.uc.curso, t.ocorrencia.periodo,
       t.ocorrencia.ano_letivo) AS horas_semanais
FROM   tiposaula t
WHERE  t.ocorrencia.periodo IN ( '1S', '2S' )
       AND t.ocorrencia.ano_letivo = '2009/2010'
GROUP  BY t.ocorrencia.uc.curso,
          t.ocorrencia.periodo,
          t.ocorrencia.ano_letivo
ORDER  BY t.ocorrencia.uc.curso,
          t.ocorrencia.periodo;

/*
 * Question f)
 */
SELECT   u.sigla_uc,
         u.get_avg_approval_rate()
FROM     ucs u
GROUP BY u.sigla_uc
ORDER BY u.get_avg_approval_rate() DESC;
