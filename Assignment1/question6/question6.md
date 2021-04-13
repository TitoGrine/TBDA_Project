# Question 6
For this question we developed two different queries, both yieldying the same result. Since both have a very distinct formulation and complexity, we chose to analyze both separately. Lets start with option A.

## Option A
Our first approach is rather simple: count the number of distinct types of classes and then select the programs whose number of types of classes matched the amount counted before. This query allowed us to get the answer very quickly and with a good degree of confidence. However, it feels like cheating because we are not actually confirming which types each program has, just that they have the right number of types.

### Query
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

### Answer
![Question 6 Answer](optionA/answer.png "Question 6 Answer")

### Execution Plans
![Execution Plan for X tables](optionA/exec_plan_X.png "Execution Plan for X tables")
![Execution Plan for Y tables](optionA/exec_plan_Y.png "Execution Plan for Y tables")
![Execution Plan for Z tables](optionA/exec_plan_Z.png "Execution Plan for Z tables")

## Option B
Our second approach is way more complex. It is heavily based on set theory. We start by creating a set with all possible pairs of program and type of class. Afterwards, we subtract this set by the set of pairs which are actually stored on the database. The resulting set is made of all pairs that had to exist in order to all programs to have classes of all types. This means that the programs which already have all types of classes are removed by subtracting the two sets. Based on this, we subtract the set of all programs on the database by the set of programs that were part of the subtraction made before and we end up with the answer.  
Translating this to SQL took a bit of effort, but the end result actually checks that the programs have every type instead of counting them. However, this query takes approximately 10 minutes to run, which means it is around 600x slower than option A. 

### Query
```sql
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
```

### Answer
![Question 6 Answer](answer.png "Question 6 Answer")

### Execution Plans
![Execution Plan for X tables](optionB/exec_plan_X.png "Execution Plan for X tables")
![Execution Plan for Y tables](exec_plan_Y.png "Execution Plan for Y tables")
![Execution Plan for Z tables](exec_plan_Z.png "Execution Plan for Z tables")