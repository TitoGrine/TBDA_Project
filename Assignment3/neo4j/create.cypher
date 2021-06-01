// create ucs
LOAD CSV WITH HEADERS FROM 'file:///ucs.csv' AS line
CREATE (:uc
  {
    codigo: line.CODIGO,
    designacao: line.DESIGNACAO,
    sigla_uc: line.SIGLA_UC,
    curso: line.CURSO
  }
);

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
    turnos: line.TURNOS,
    n_aulas: line.N_AULAS,
    horas_turno: line.HORAS_TURNO
  }
)
CREATE (o)-[:aulas]->(t);

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

// create dsd
LOAD CSV WITH HEADERS FROM 'file:///dsd.csv' AS line
MATCH (d:Docente // match foreign keys
  {
    nr: toInteger(line.NR)
  }
)
MATCH (t:TipoAula
  {
    id: toInteger(line.ID)
  }
)
CREATE (d)-[:dsd
  {
    horas: toInteger(line.HORAS),
    fator: toInteger(line.FATOR),
    ordem: toInteger(line.ORDEM)
  }
]->(t);
