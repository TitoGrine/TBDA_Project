/** 2 
    Questoes:
    - Será que se devia fazer join pelas ocorrencias?
    - Basta retornar o tipo e total_horas ou mantem-se o curso e ano_letivo?
*/
SELECT
    ucs.curso,
    tipo.ano_letivo,
    tipo.tipo,
    SUM(turnos * horas_turno) as total_horas
FROM
    XUCS ucs
JOIN
    XTIPOSAULA tipo ON
        tipo.codigo = ucs.codigo
WHERE
    ucs.curso = 433 AND
    tipo.ano_letivo = '2004/2005'
GROUP BY
    ucs.curso,
    tipo.ano_letivo,
    tipo.tipo;

/** 6 (versão rafada)
    Resposta rafada, mas serve para ver a solução:
    (2021, 4495, 9461, 9508)
*/
SELECT temp.curso
FROM (
    SELECT DISTINCT ucs.curso, tipo.tipo
    FROM
        XUCS ucs
    JOIN
        XTIPOSAULA tipo ON
            tipo.codigo = ucs.codigo) temp
HAVING COUNT(temp.tipo) = (SELECT COUNT(DISTINCT tipo) FROM XTIPOSAULA)
GROUP BY temp.curso
ORDER BY temp.curso;

CREATE VIEW curso_tipo_permutations AS
SELECT *
FROM (
    SELECT DISTINCT curso
    FROM XUCS),(
    SELECT DISTINCT tipo
    FROM XTIPOSAULA);

SELECT DISTINCT
    uc.curso
FROM 
    XUCS uc
WHERE
    uc.curso NOT IN (
        SELECT DISTINCT
            ctp.curso
        FROM (
            SELECT DISTINCT
                curso,
                tipo
            FROM
                XUCS,
                XTIPOSAULA) ctp
        WHERE
            (ctp.curso, ctp.tipo) NOT IN (
                SELECT DISTINCT
                    ucs.curso,
                    tipo.tipo
                FROM
                    XUCS ucs
                JOIN
                    XTIPOSAULA tipo ON
                        tipo.codigo = ucs.codigo))
ORDER BY
    uc.curso;

/*SELECT curso
FROM XUCS
WHERE curso NOT IN(
SELECT *
FROM
    curso_tipo_permutations
MINUS
SELECT DISTINCT ucs.curso, tipo.tipo
FROM
    XUCS ucs
JOIN
    XTIPOSAULA tipo ON
        tipo.codigo = ucs.codigo);*/