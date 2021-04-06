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
GROUP BY ucs.curso, tipo.ano_letivo, tipo.tipo;

/* 6 */
