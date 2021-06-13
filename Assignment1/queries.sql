-- Question 1

SELECT ucs.codigo,
   ucs.designacao,
   ucs.curso,
   ocorrencias.ano_letivo,
   ocorrencias.inscritos,
   tipo.tipo,
   tipo.turnos
FROM   xocorrencias ocorrencias
   JOIN xtiposaula tipo
     ON tipo.codigo = ocorrencias.codigo
        AND tipo.ano_letivo = ocorrencias.ano_letivo
        AND tipo.periodo = ocorrencias.periodo
   JOIN xucs ucs
     ON ucs.codigo = ocorrencias.codigo
        AND ucs.designacao = 'Bases de Dados'
        AND ucs.curso = 275;
        
DROP INDEX ZUCS_IDX_CURSO_DESIGNACAO;
CREATE INDEX ZUCS_IDX_CURSO_DESIGNACAO ON ZUCS(curso, designacao);

-- Question 2

SELECT ucs.curso,
       tipo.ano_letivo,
       tipo.tipo,
       SUM(turnos * horas_turno) AS total_horas
FROM   xucs ucs
       JOIN xtiposaula tipo
         ON tipo.codigo = ucs.codigo
WHERE  ucs.curso = 233
       AND tipo.ano_letivo = '2004/2005'
GROUP  BY ucs.curso,
          tipo.ano_letivo,
          tipo.tipo;

DROP INDEX ZUCS_IDX_CURSO_CODIGO;
CREATE UNIQUE INDEX ZUCS_IDX_CURSO_CODIGO ON ZUCS(curso, codigo);
          
-- Question 3

-- a)

SELECT DISTINCT ocorrencias.codigo
FROM   xocorrencias ocorrencias
WHERE  ocorrencias.ano_letivo = '2003/2004'
       AND ocorrencias.codigo NOT IN (SELECT aulas.codigo
                                      FROM   xtiposaula aulas
                                             join xdsd dsd
                                               ON aulas.id = dsd.id
                                      WHERE  aulas.ano_letivo = '2003/2004'); 
                                      
DROP INDEX ZTIPOSAULA_IDX_ANO_LETIVO_ID_CODIGO;
CREATE TABLE ZTIPOSAULA_IDX_ANO_LETIVO_ID_CODIGO ON ZTIPOSAULA(ano_letivo, id, codigo)

-- b)

SELECT codigo
FROM   (SELECT DISTINCT ocorrencias.codigo codigo,
                        aulas.id           id
        FROM   xocorrencias ocorrencias
               LEFT OUTER JOIN (SELECT aulas.codigo codigo,
                                       aulas.id     id
                                FROM   xtiposaula aulas
                                       JOIN xdsd dsd
                                         ON aulas.id = dsd.id
                                WHERE  aulas.ano_letivo = '2003/2004') aulas
                            ON ocorrencias.codigo = aulas.codigo
        WHERE  ocorrencias.ano_letivo = '2003/2004')
WHERE  id IS NULL;  

DROP INDEX ZTIPOSAULA_IDX_ANO_LETIVO_ID_CODIGO;
CREATE INDEX ZTIPOSAULA_IDX_ANO_LETIVO_ID_CODIGO ON ZTIPOSAULA(ano_letivo, id, codigo); 

-- Question 4

SELECT docentes.nr,
       docentes.nome,
       dsd.fator * dsd.horas AS total_horas_semanais,
       tipo.tipo
FROM   xdsd dsd
       JOIN xdocentes docentes
         ON docentes.nr = dsd.nr
       JOIN xtiposaula tipo
         ON tipo.id = dsd.id
            AND tipo.ano_letivo = '2003/2004'
WHERE  dsd.fator IS NOT NULL
       AND dsd.fator * dsd.horas = (SELECT Max(sub_dsd.fator * sub_dsd.horas)
                                    FROM   xdsd sub_dsd
                                           JOIN xtiposaula sub_tipo
                                             ON sub_tipo.id = sub_dsd.id
                                                AND sub_tipo.ano_letivo = '2003/2004'
                                    WHERE  sub_dsd.fator IS NOT NULL
                                           AND sub_tipo.tipo = tipo.tipo)
ORDER  BY tipo.tipo;

DROP INDEX ZTIPOSAULA_IDX_ANO_LETIVO;
CREATE INDEX ZTIPOSAULA_IDX_ANO_LETIVO ON ZTIPOSAULA(ano_letivo);

-- Question 5

SELECT aulas.codigo,
       aulas.ano_letivo,
       aulas.periodo,
       ( aulas.horas_turno * aulas.turnos ) horas
FROM   ztiposaula aulas
WHERE  aulas.tipo = 'OT'
       AND ( aulas.ano_letivo = '2002/2003'
              OR aulas.ano_letivo = '2003/2004' ); 

-- a)

DROP INDEX ZTIPOSAULA_IDX_TIPO_ANO_LETIVO;
CREATE INDEX ZTIPOSAULA_IDX_TIPO_ANO_LETIVO ON ZTIPOSAULA(tipo, ano_letivo);

-- b)

DROP INDEX ZTIPOSAULA_IDX_ANO_LETIVO_TIPO;
CREATE BITMAP INDEX ZTIPOSAULA_IDX_ANO_LETIVO_TIPO ON ZTIPOSAULA(ano_letivo, tipo); 

-- Question 6

-- Option A

SELECT ct.curso
FROM   (SELECT DISTINCT ucs.curso,
                        tipo.tipo
        FROM   xucs ucs
               JOIN xtiposaula tipo
                 ON tipo.codigo = ucs.codigo) ct
HAVING Count(ct.tipo) = (SELECT Count(DISTINCT tipo)
                         FROM   xtiposaula)
GROUP  BY ct.curso;

DROP INDEX ZTIPOSAULA_IDX_CODIGO_TIPO;
CREATE INDEX ZTIPOSAULA_IDX_CODIGO_TIPO ON ZTIPOSAULA(codigo, tipo);

-- Option B

SELECT DISTINCT uc.curso -- Select 4
FROM   xucs uc
WHERE  uc.curso NOT IN (SELECT DISTINCT ctp.curso -- Select 3
                        FROM   (SELECT DISTINCT curso, tipo -- Select 2
                                FROM   xucs,
                                       xtiposaula) ctp
                        WHERE  ( ctp.curso, ctp.tipo )
                                NOT IN (SELECT DISTINCT ucs.curso, tipo.tipo -- Select 1
                                         FROM   xucs ucs
                                                JOIN xtiposaula tipo
                                                  ON tipo.codigo = ucs.codigo));

DROP INDEX ZUCS_IDX_CURSO_CODIGO;
CREATE UNIQUE INDEX ZUCS_IDX_CURSO_CODIGO ON ZUCS(curso, codigo);

DROP INDEX ZTIPOSAULA_IDX_CODIGO_TIPO;
CREATE INDEX ZTIPOSAULA_IDX_CODIGO_TIPO ON ZTIPOSAULA(codigo, tipo);

DROP INDEX ZTIPOSAULA_IDX_TIPO;
CREATE BITMAP INDEX ZTIPOSAULA_IDX_TIPO ON ZTIPOSAULA(tipo);

