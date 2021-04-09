## Query
```sql
SELECT
    temp.curso
FROM (
    SELECT DISTINCT
        ucs.curso,
        tipo.tipo
    FROM
        XUCS ucs
    JOIN
        XTIPOSAULA tipo ON
            tipo.codigo = ucs.codigo) temp
HAVING
    COUNT(temp.tipo) = (
    SELECT 
        COUNT(DISTINCT tipo)
    FROM 
        XTIPOSAULA)
GROUP BY
    temp.curso
ORDER BY
    temp.curso;
```

## Answer
![Question 6 Answer](answer.png "Question 6 Answer")

## Execution Plans
![Execution Plan for X tables](exec_plan_X.png "Execution Plan for X tables")
VS.
![Execution Plan for X tables](exec_plan_X_bigger.png "Execution Plan for X tables")
![Execution Plan for Y tables](exec_plan_Y.png "Execution Plan for Y tables")
![Execution Plan for Z tables](exec_plan_Z.png "Execution Plan for Z tables")
