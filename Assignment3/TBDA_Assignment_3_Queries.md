## Queries

### MongoDB

**a)**

```javascript
db.tiposaula.aggregate(
    [
        {
            $match:{
                "ocorrencia.uc.curso": 233,
                "ocorrencia.ano_letivo": "2004/2005"
            }
        },
        {
            $group: {
                _id: "$tipo",
                "class_hours": { $sum: { $multiply: ["$horas_turno", "$turnos"]}},
                "course": { $first: "$ocorrencia.uc.curso" },
                "year": { $first: "$ocorrencia.ano_letivo" }
            }
        },
        {
            $project: {
                _id: 0,
                "type": "$_id",
                "class_hours": 1,
                "course": 1,
                "year": 1
            }
        }
    ]
);
```

**b)**

```javascript
db.tiposaula.aggregate(
    [
        {
            $match: {
                "ocorrencia.ano_letivo": "2003/2004"
            }
        },
        {
            $addFields: {
                "hours_assigned": {
                    $reduce: { 
                        input: "$docentes",
                        initialValue: 0,
                        in: { $add: ["$$value", "$$this.horas"]}
                    }
                }
            }
        },
        {
            $group: {
                _id: "$ocorrencia.uc.codigo",
                "total_hours_required": { $sum: { $multiply: ["$horas_turno", "$turnos"]}},
                "total_hours_assigned": { $sum: "$hours_assigned" }
            }
        },
        {
            $project: {
                code: "$_id",
                hours_required: "$total_hours_required",
                hours_assigned: "$total_hours_assigned",
                diff: { $ne: ["$total_hours_assigned", "$total_hours_required"] }
            }
        },
        {
            $match: { "diff": true }
        },
        {
            $project: {
                "_id": 0,
                "code": 1,
                "hours_required": 1,
                "hours_assigned": 1,
            }
        },
        { 
            $sort: { "code": 1 }
        }
    ]
);
```

**c)**

```javascript
db.tiposaula.aggregate(
    [
        {
            $match: { "ocorrencia.ano_letivo": "2003/2004" }
        },
        { $unwind: "$docentes" },
        { $group: {
            _id: { 
                    "docente": "$docentes.docente.nr",
                    "type": "$tipo"
                },
            "nome": { $first: "$docentes.docente.nome" },
            "hours": { $sum: "$docentes.horas" }
        	}
        },
        { $sort: { "hours": -1 } },
        { $group: {
            _id: "$_id.type",
            "nr": { $first: "$_id.docente" },
            "nome": { $first: "$nome" },
            "hours": { $first: "$hours" }
        	}
        },
        {
            $project: {
                "_id": 0,
                "type": "$_id",
                "nr": 1,
                "nome": 1,
                "hours": 1
            }
        }
    ]
);
```

**d)**

```javascript
db.tiposaula.aggregate(
    [
        {
            $match: {
                "ocorrencia.ano_letivo": {
                    $in: ["2001/2002", "2002/2003", "2003/2004", "2004/2005"]
                }
            }
        },
        {   $unwind: "$docentes"   },
        {
            $match: { "docentes.docente.categoria": { $exists: true, $ne: null } }
        },
        {
            $group: {
                _id: {
                    "docente": "$docentes.docente.nr",
                    "category": "$docentes.docente.categoria",
                    "year": "$ocorrencia.ano_letivo"
                },
                "name": { $first: "$docentes.docente.nome" },
                "avg_hours": { $avg: "$docentes.horas" }
            }
        },
        {
            $project: {
                _id: 0,
                "category": "$_id.category",
                "year": "$_id.year",
                "name": 1,
                "avg_hours": 1
            }
        },
        {
            $sort: { "name": 1, "year": 1 }
        }
    ]
);
```

**e)**

```javascript
db.tiposaula.aggregate(
    [
        {
            $match: { 
                "ocorrencia.ano_letivo": "2009/2010",
                "ocorrencia.periodo": { $in: ['1S', '2S'] },
                "ocorrencia.uc.curso": {
                        $exists: true,
                        $ne: null
                   }
                }
        },
        { $group: {
            _id: { 
                    "course": "$ocorrencia.uc.curso",
                    "semester": "$ocorrencia.periodo"
                },
            "total_hours": { $sum: "$horas_turno" }
        	}
        },
        {
            $project: {
                _id: 0,
                "course": "$_id.course",
                "semester": "$_id.semester",
                "total_hours": 1
            }
        },
        {
            $sort: { "course": 1, "semester": 1 }
        }
    ]
);
```

**f)**

```javascript
db.tiposaula.aggregate(
    [
        { $unwind: "$docentes" },
        { $match: { "docentes.docente.nome": "Gabriel de Sousa Torcato David" } },
        { $sortByCount: "$ocorrencia.uc.codigo" },
        {
            $lookup: {
                from: "tiposaula",
                localField: "_id",
                foreignField: "ocorrencia.uc.codigo",
                as: "tipoaula"
            }
        },
        { $project: { 
                "_id": 0,
                "code": "$_id",
                "sigla": { $arrayElemAt: ["$tipoaula.ocorrencia.uc.sigla_uc", 0] },
                "designation": { $arrayElemAt: ["$tipoaula.ocorrencia.uc.designacao", 0] },
                "count": 1
            }
        },
    ]
);
```

### Neo4j

**a)**
```graphql
MATCH (u:uc {curso: 233})-[:contem]->(o:ocorrencia {ano_letivo: '2004/2005'})-[:aulas]->(t:tipoaula)
WITH u.curso as curso, o.ano_letivo as ano_letivo, t.tipo as tipo, sum(t.horas_turno * t.turnos) as sumHoras
RETURN curso, ano_letivo, tipo, sumHoras;
```

**b)**

```graphql
MATCH (u1:uc)-[:contem]->(:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)
WITH u1.codigo as codigo1, sum(t.horas_turno * t.turnos) as total_required
MATCH (u2:uc)-[:contem]->(:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)
OPTIONAL MATCH (t)<-[ds:dsd]-()
WITH u2.codigo as codigo2, codigo1, round(sum(ds.horas), 10) as service_assigned, total_required
WHERE codigo2 = codigo1 AND total_required <> service_assigned
RETURN codigo2, total_required, service_assigned
ORDER BY codigo2;
```

**c)**

```graphql
MATCH (:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t1:tipoaula)<-[ds1:dsd]-(d1:docente)
WITH d1.nr as nr, d1.nome as nome, t1.tipo as tipo1, sum(ds1.horas) as temp_total
WITH tipo1, max(temp_total) as max_total
MATCH (:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t2:tipoaula)<-[ds2:dsd]-(d2:docente)
WITH d2.nr as nr, d2.nome as nome, tipo1, t2.tipo as tipo2, sum(ds2.horas) as total_horas, max_total
WHERE tipo1 = tipo2 AND total_horas = max_total
RETURN nr, nome, tipo1, total_horas;
```

**d)**

```graphql
MATCH (o:ocorrencia)-[:aulas]->(t:tipoaula)<-[ds:dsd]-(d:docente)
WHERE o.ano_letivo IN ['2001/2002', '2002/2003', '2003/2004','2004/2005'] AND d.categoria IS NOT NULL
WITH d.categoria as categoria, d.nr as nr, d.nome as nome, o.ano_letivo as ano_letivo, avg(ds.horas) as media_horas
ORDER BY nome, ano_letivo
RETURN categoria, nome, ano_letivo, media_horas;
```

**e)**

```graphql
MATCH (u:uc)-[:contem]->(o:ocorrencia {ano_letivo: '2009/2010'})-[:aulas]->(t:tipoaula)
WHERE o.periodo in ['1S', '2S'] AND u.curso IS NOT NULL
WITH u.curso as curso, o.periodo as periodo, sum(t.horas_turno) as horas_semanais
ORDER BY curso, periodo
RETURN curso, periodo, horas_semanais;
```

**f)**

```graphql
MATCH
  (prof:docente {nome: 'Gabriel de Sousa Torcato David'}),
  (tbda:uc {designacao: 'Tecnologias de Bases de Dados'}),
  path = (prof)-[*..5]-(tbda)
RETURN path;
```
