## Query
```sql
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
```

## Answer
![Question 2 Answer](answer.png "Question 2 Answer")

## Execution Plans
![Execution Plan for X tables](exec_plan_X.png "Execution Plan for X tables")
![Execution Plan for Y tables](exec_plan_Y.png "Execution Plan for Y tables")
![Execution Plan for Z tables](exec_plan_Z.png "Execution Plan for Z tables")
