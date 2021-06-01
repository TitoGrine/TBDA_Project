select
    json_object(
        '_id' value tp.id,
        'tipo' value tp.tipo,
        'horas_turno' value tp.horas_turno,
        'n_aulas' value tp.n_aulas,
        'turnos' value tp.turnos,
        'docentes' value (select
                            json_arrayagg(
                                json_object(
                                    'horas' value dsd.horas,
                                    'ordem' value dsd.ordem,
                                    'fator' value dsd.fator,
                                    'docente' value (select
                                                        json_object(
                                                            'nr' value d.nr,
                                                            'nome' value d.nome,
                                                            'estado' value d.estado,
                                                            'apelido' value d.apelido,
                                                            'proprio' value d.proprio,
                                                            'categoria' value d.categoria,
                                                            'sigla' value d.sigla
                                                        )
                                                        from xdocentes d
                                                        where d.nr = dsd.nr) returning clob
                                ) returning clob
                            )
                            from xdsd dsd
                            where dsd.id = tp.id),
        'ocorrencia' value (select
                                json_object(
                                    'ano_letivo' value o.ano_letivo,
                                    'periodo' value o.periodo,
                                    'inscritos' value o.inscritos,
                                    'conteudo' value o.conteudo,
                                    'objetivos' value o.objetivos,
                                    'aprovados' value o.aprovados,
                                    'departamento' value o.departamento,
                                    'com_frequencia' value o.com_frequencia,
                                    'uc' value (select
                                                    json_object(
                                                        'codigo' value u.codigo,
                                                        'sigla_uc' value u.sigla_uc,
                                                        'designacao' value u.designacao,
                                                        'curso' value u.curso
                                                    )
                                                from xucs u
                                                where u.codigo = o.codigo) returning clob
                                )
                            from xocorrencias o
                            where o.ano_letivo = tp.ano_letivo
                                and o.codigo = tp.codigo
                                and o.periodo = tp.periodo) returning clob
    ) as all_data
from xtiposaula tp;