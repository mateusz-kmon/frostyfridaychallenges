-- https://frostyfriday.org/2022/09/30/week-16-intermediate/

create or replace temporary view week16_parsed as
select 
  w.word
, w.url
, m.value:partOfSpeech::string as part_of_speach
, m.value:synonyms as general_synonyms
, m.value:antonyms as general_antonyms
, d.value:definition::string as definition
, d.value:example::string as example_if_applicable
, d.value:synonyms as definitional_synonyms
, d.value:antonyms as definitional_antonyms
from week16 w
, lateral flatten(w.definition[0]:meanings, outer=>true) m
, lateral flatten(m.value:definitions, outer=>true) d
;

select *
from week16_parsed sub
where word like 'l%'
;

select count(word), count(distinct word)
from week16_parsed sub
;



alter table week16 add search optimization on equality(definition:meanings:definitions:definition);
--Error:   Expression EQUALITY(IDX_SRC_TABLE.VC_4) cannot be used in search optimization.