-- comandos de criação de tabela para
-- o hospital miserere da boa morte

-- para rodar no postgresql (via adminer ou pelo psql prompt)

-- observações:
-- o datetime do MySQL é o timestamp do postgresql
-- serial is used in place of auto increment in postgres

-- updating/deleting/adding managers and their departments must happen in a single transaction


create database hospital with encoding 'UTF8';
\c hospital


create table pessoa (
    cpf bigint,
    nome text not null,
    endereco text not null,
    telefone text not null,
    nascimento date not null,

    primary key (cpf)
);

create table paciente (
    cpf bigint,
    tipo_sanguineo varchar(3),
    plano_saude text,

    primary key (cpf),

    foreign key (cpf)
        references pessoa (cpf)
        on update cascade
        on delete cascade,

    check (tipo_sanguineo is null or
           tipo_sanguineo = 'A+' or tipo_sanguineo = 'A-' or
           tipo_sanguineo = 'AB+' or tipo_sanguineo = 'AB-' or
           tipo_sanguineo = 'B+' or tipo_sanguineo = 'B-' or
           tipo_sanguineo = 'O+' or tipo_sanguineo = 'O-')
);

create table departamento (
    nome varchar(20),
    funcao text not null,

    -- must add the foreign key constraint later
    CPF_gerente bigint not null, 

    primary key (nome)
);

create table funcionario (
    cpf bigint,
    departamento_nome varchar(20) not null,
    salario integer not null,
    data_contratacao date not null,
    data_demissao date,
    formacao text not null,

    primary key (cpf),

    foreign key (cpf)
        references pessoa (cpf)
        on update cascade
        on delete cascade,

    foreign key (departamento_nome)
        references departamento (nome)
        on update cascade
        on delete no action, -- don't allow deleting a department with people still in it

    check (data_demissao is null or data_demissao > data_contratacao),

    check (salario > 0)
);

create table tecnico (
    cpf bigint,

    primary key (cpf),

    foreign key (cpf)
        references funcionario (cpf)
        on delete cascade
        on update cascade
);

create table medico (
    cpf bigint,
    especialidade text not null,
    crm varchar(20) not null,

    primary key (cpf),

    foreign key (cpf)
        references funcionario (cpf)
        on update cascade
        on delete cascade
);

create table enfermeiro (
    cpf bigint,
    especialidade text not null,

    primary key (cpf),

    foreign key (cpf)
        references funcionario (cpf)
        on update cascade
        on delete cascade
);

create table gerente (
    cpf bigint,
    nome_departamento_gerenciado varchar(20), -- redundant

    primary key (cpf),

    foreign key (cpf)
        references funcionario (cpf)
        on update cascade
        on delete cascade,

    foreign key (nome_departamento_gerenciado)
        references departamento (nome)
        on update cascade
        on delete set null
);


alter table departamento
    add foreign key (CPF_gerente)
        references gerente (cpf)
        on update cascade
        on delete no action; 
-- no boat without a commander. this arrests the deletion of the manager. btw NO ACTION is the default


create table tratamento (
    nome text,
    duracao text not null,
    custo money not null,

    primary key (nome)
);

create table contra_indicacao (
    nome text,

    primary key (nome)
);

create table efeito_colateral (
    nome_tratamento text,
    nome_contra_indicacao text,

    primary key (nome_tratamento, nome_contra_indicacao),

    foreign key (nome_tratamento)
        references tratamento (nome)
        on update cascade
        on delete cascade,

    foreign key (nome_contra_indicacao)
        references contra_indicacao (nome)
        on update cascade
        on delete cascade  
);

create table medicamento (
    nome text,
    registro_governo text not null,
    formula text not null,
    dose text not null,

    primary key (nome),

    foreign key (nome)
        references tratamento (nome)
        on update cascade
        on delete cascade
);

create table terapia (
    nome text,
    tipo text not null,

    primary key (nome),

    foreign key (nome)
        references tratamento (nome)
        on update cascade
        on delete cascade
);

create table doenca (
    nome_cientifico text,
    nome_popular text,
    tipo text,
    descricao text not null,

    primary key (nome_cientifico)
);

create table tratamento_trata_doenca (
    nome_tratamento text,
    nome_cientifico_doenca text,

    primary key (nome_tratamento, nome_cientifico_doenca),

    foreign key (nome_tratamento)
        references tratamento (nome)
        on update cascade
        on delete cascade,

    foreign key (nome_cientifico_doenca)
        references doenca (nome_cientifico)
        on update cascade
        on delete cascade
);

create table sintoma (
    nome_cientifico text,
    nome_popular text,
    tipo text,
    descricao text not null,

    primary key (nome_cientifico)
);

create table doenca_exibe_sintoma (
    doenca_nome_cientifico text,
    sintoma_nome_cientifico text,

    primary key (doenca_nome_cientifico, sintoma_nome_cientifico),

    foreign key (doenca_nome_cientifico)
        references doenca (nome_cientifico)
        on delete cascade 
        on update cascade,

    foreign key (sintoma_nome_cientifico)
        references sintoma (nome_cientifico)
        on delete cascade 
        on update cascade
);

create table exame (
    tipo text,

    primary key (tipo)
);

create table equipamento (
    numero_patrimonio text,
    tipo text,

    primary key (numero_patrimonio)
);

create table tecnico_sabe_fazer_exame (
    tipo_exame text,
    cpf_tecnico bigint,

    primary key (tipo_exame, cpf_tecnico),

    foreign key (tipo_exame)
        references exame (tipo)
        on update cascade
        on delete cascade,

    foreign key (cpf_tecnico)
        references tecnico (cpf)
        on update cascade
        on delete cascade
);

create table tecnico_opera_equipamento (
    cpf_tecnico bigint,
    numero_patrimonio_equipamento text,

    primary key (cpf_tecnico, numero_patrimonio_equipamento),

    foreign key (cpf_tecnico)
        references tecnico (cpf)
        on update cascade
        on delete cascade,

    foreign key (numero_patrimonio_equipamento)
        references equipamento (numero_patrimonio)
        on update cascade
        on delete cascade 
);

create table medico_interna_paciente (
    cpf_paciente bigint,
    data_horario_entrada timestamp,
    cpf_medico bigint,
    data_horario_saida timestamp,
    leito text not null,

    primary key (cpf_paciente, data_horario_entrada),

    foreign key (cpf_paciente)
        references paciente (cpf)
        on update cascade
        on delete cascade,

    foreign key (cpf_medico)
        references medico (cpf)
        on update cascade
        on delete set null,

    check (data_horario_saida is null
           or data_horario_saida > data_horario_entrada)
);

create table analise_laboratorial (
    paciente_cpf bigint,
    data_horario_exame timestamp,
    exame_tipo text not null,
    resultado text,
    laboratorio text not null,
    cpf_tecnico_responsavel bigint, 

    primary key (paciente_cpf, data_horario_exame),
    
    foreign key (paciente_cpf)
        references paciente(cpf)
        on delete cascade 
        on update cascade,

    foreign key (exame_tipo)
        references exame (tipo)
        on delete no action -- halt! should't delete an exam type for which there exists a patient result
        on update cascade,

    foreign key (cpf_tecnico_responsavel)
        references tecnico (cpf)
        on delete set null
        on update cascade
);

create table caso (
    paciente_cpf bigint,
    doenca_nome_cientifico text,
    data_horario_diagnostico timestamp,
    status text not null,
    prognostico text,

    primary key (paciente_cpf, doenca_nome_cientifico, data_horario_diagnostico),

    foreign key (paciente_cpf)
        references paciente (cpf) 
        on delete cascade
        on update cascade,

    foreign key (doenca_nome_cientifico)
        references doenca (nome_cientifico) 
        on delete cascade
        on update cascade
);

create table consulta (
    paciente_cpf bigint,
    data_horario_consulta timestamp,
    medico_cpf bigint,
    sala integer not null,

    primary key (paciente_cpf, data_horario_consulta),

    foreign key (paciente_cpf)
        references paciente (cpf)
        on delete cascade
        on update cascade,

    foreign key (medico_cpf)
        references medico (cpf)
        on delete set null
        on update cascade
);

create table receita (
    paciente_cpf bigint,
    data_horario_consulta timestamp,
    nome_tratamento text,

    primary key (paciente_cpf, data_horario_consulta, nome_tratamento),

    foreign key (paciente_cpf, data_horario_consulta)
        references consulta (paciente_cpf, data_horario_consulta)
        on update cascade
        on delete cascade,

    foreign key (nome_tratamento)
        references tratamento (nome)
        on update cascade
        on delete cascade
);

create table ficha_anamnese (
    paciente_cpf bigint,
    data_horario_consulta timestamp,
    tipo text not null,
    conteudo text not null,

    primary key (paciente_cpf, data_horario_consulta),

    foreign key (paciente_cpf, data_horario_consulta)
        references consulta (paciente_cpf, data_horario_consulta)
        on delete cascade 
        on update cascade
);




