// create ucs
LOAD CSV WITH HEADERS FROM 'file:///ucs.csv' AS line
CREATE (:uc
  {
    codigo: line.CODIGO,
    designacao: line.DESIGNACAO,
    sigla_uc: line.SIGLA_UC,
    curso: toInteger(line.CURSO)
  }
);
// create UC index for faster joins
CREATE INDEX uc_codigo_idx IF NOT EXISTS
FOR (u:uc)
ON (u.codigo);

// create ocorrencias
LOAD CSV WITH HEADERS FROM 'file:///ocorrencias.csv' AS line
MATCH (u:uc // match foreign key
  {
    codigo: line.CODIGO
  }
)
CREATE (o:ocorrencia
  {
    codigo: line.CODIGO,
    ano_letivo: line.ANO_LETIVO,
    periodo: line.PERIODO,
    inscritos: toInteger(line.INSCRITOS),
    com_frequencia: toInteger(line.COM_FREQUENCIA),
    aprovados: toInteger(line.APROVADOS),
    objetivos: line.OBJETIVOS,
    conteudo: line.CONTEUDO,
    departamento: line.DEPARTAMENTO
  }
)
CREATE (u)-[:contem]->(o);
// create ocorrencia index for faster joins
CREATE INDEX ocorrencia_composite_idx IF NOT EXISTS
FOR (o:ocorrencia)
ON (o.codigo, o.ano_letivo, o.periodo);

// create tiposaula
LOAD CSV WITH HEADERS FROM 'file:///tiposaula.csv' AS line
MATCH (o:ocorrencia // match foreign keys
  {
    codigo: line.CODIGO,
    ano_letivo: line.ANO_LETIVO,
    periodo: line.PERIODO
  }
)
CREATE (t:tipoaula
  {
    id: toInteger(line.ID),
    tipo: line.TIPO,
    ano_letivo: line.ANO_LETIVO,
    periodo: line.PERIODO,
    codigo: line.CODIGO,
    turnos: toFloat(line.TURNOS),
    n_aulas: toInteger(line.N_AULAS),
    horas_turno: toFloat(line.HORAS_TURNO)
  }
)
CREATE (o)-[:aulas]->(t);
// create tipoaula index for faster joins
CREATE INDEX tipoaula_id_idx IF NOT EXISTS
FOR (t:tipoaula)
ON (t.id);

// create docentes
LOAD CSV WITH HEADERS FROM 'file:///docentes.csv' AS line
CREATE (:docente
  {
    nr: toInteger(line.NR),
    nome: line.NOME,
    sigla: line.SIGLA,
    categoria: line.CATEGORIA,
    proprio: line.PROPRIO,
    apelido: line.APELIDO,
    estado: line.ESTADO
  }
);
// create tipoaula index for faster joins
CREATE INDEX docente_nr_idx IF NOT EXISTS
FOR (d:docente)
ON (d.nr);

// create dsd
LOAD CSV WITH HEADERS FROM 'file:///dsd.csv' AS line
MATCH (d:docente // match foreign keys
  {
    nr: toInteger(line.NR)
  }
)
MATCH (t:tipoaula
  {
    id: toInteger(line.ID)
  }
)
CREATE (d)-[:dsd
  {
    horas: toFloat(line.HORAS),
    fator: toFloat(line.FATOR),
    ordem: toInteger(line.ORDEM)
  }
]->(t);


// delete all nodes and relations
MATCH (n) DETACH DELETE n;

// a)
// How  many  class  hours  of  each  type  did  the  program  233  got  in  year  2004/2005?
MATCH (u:uc {curso: 233})-[:contem]->(o:ocorrencia {ano_letivo: '2004/2005'})-[:aulas]->(t:tipoaula)
WITH u.curso as curso, o.ano_letivo as ano_letivo, t.tipo as tipo, sum(t.horas_turno * t.turnos) as sumHoras
RETURN curso, ano_letivo, tipo, sumHoras

// b)
// Which  courses  (show  the  code,  total  class  hours  required,  total  classes  assigned)
// have a difference between total class hours required and the service actually assigned in year 2003/2004?
MATCH (u:uc)-[:contem]->(:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)<-[ds:dsd]-(:docente)
WITH u.codigo as codigo, sum(t.horas_turno * t.turnos) as total_required, sum(ds.horas) as service_assigned
ORDER BY codigo
WHERE total_required <> service_assigned
RETURN codigo, total_required, service_assigned

// c)
// Who  is  the  professor  with  more  class  hours  for  each  type  of  class,  in  the  academic  year  2003/2004? 
// Show  the  number  and  name  of  the  professor,  the  type of class and the total of class hours times the factor.
MATCH (:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)<-[ds:dsd]-(d:docente)
WITH d.nr as nr, d.nome as nome, t.tipo as tipo, sum(ds.horas) as total_horas
RETURN nr, nome, tipo, total_horas

CALL {
  MATCH (:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)<-[ds:dsd]-(d:docente)
  WITH d.nr as nr, d.nome as nome, t.tipo as tipo, sum(ds.horas) as total_horas
  RETURN nr, nome, tipo, total_horas
}
WITH apoc.agg.maxItems(total_horas, tipo) as cenas
RETURN cenas

MATCH (:ocorrencia {ano_letivo: '2003/2004'})-[:aulas]->(t:tipoaula)<-[ds:dsd]-(d:docente)
WITH d.nr as nr, d.nome as nome, t.tipo as tipo, sum(ds.horas) as total_horas
ORDER BY tipo DESC, total_horas DESC
RETURN nr, nome, tipo, collect(total_horas)[0] as 

// d)
// Which  is  the  average  number  of  hours  by  professor  by  year  in  each  category, 
// in the years between 2001/2002 and 2004/2005?
MATCH (o:ocorrencia)-[:aulas]->(t:tipoaula)<-[ds:dsd]-(d:docente)
WHERE o.ano_letivo IN ['2001/2002', '2002/2003', '2003/2004','2004/2005']
WITH d.categoria as categoria, d.nome as nome, o.ano_letivo as ano_letivo, avg(ds.horas) as media_horas
ORDER BY nome, ano_letivo
RETURN categoria, nome, ano_letivo, media_horas

// e)
// Which  is  the  total  hours  per  week,  on  each  semester,  that  a 
// hypothetical student enrolled in every course of a single curricular year from each program would get.
MATCH (u:uc)-[:contem]->(o:ocorrencia {ano_letivo: '2009/2010'})-[:aulas]->(t:tipoaula)
WHERE t.periodo in ['1S', '2S']
WITH u.curso as curso, o.periodo as periodo, sum(t.horas_turno) as horas_semanais
ORDER BY curso, periodo
RETURN curso, periodo, horas_semanais;
