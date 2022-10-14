-- https://frostyfriday.org/2022/10/07/week-17-intermediate/


-- limit points to Brooklyn
create or replace temporary table brooklyn_node as
select *
from marketplace_newyork_share.new_york.v_osm_ny_node
where id in (
    select distinct id
    from marketplace_newyork_share.new_york.v_osm_ny_node
    , lateral flatten(tags) f1
    where f1.value:key::string='addr:city' and f1.value:value::string='Brooklyn'
)
;
--  select count(*) as cnt from brooklyn_node; --2556


-- mark the reversed engineered rectangles toghether with nominated "central nodes"
create or replace temporary table end_result_polygons as
select no, wkt, to_geography(wkt) as coordinates
, case 
    when no=1 then st_centroid(st_collect(st_point(st_xmin(coordinates), st_ymax(coordinates)), st_point(st_xmin(coordinates), st_ymin(coordinates)))) --ml
    when no=2 then st_point(st_xmin(coordinates), st_ymin(coordinates)) --bl
    else st_centroid(coordinates)
  end as centro
from values
 (1, 'POLYGON((-73.95784735679626 40.731909290731465,-73.9521825313568 40.732071890560206,-73.95209670066833 40.72686849895493,-73.95776152610779 40.72683597647796,-73.95784735679626 40.731909290731465))')
,(2, 'POLYGON((-73.95761132240295 40.729844238338586,-73.9575469493866 40.724022722071794,-73.94969344139099 40.723908888465445,-73.9499294757843 40.7299255408258,-73.95761132240295 40.729844238338586))')
,(3, 'POLYGON((-73.9836287498474 40.68948969132276,-73.99328470230103 40.68988017892701,-73.99311304092407 40.694533313435784,-73.98345708847046 40.694240468398505,-73.9836287498474 40.68948969132276))')
,(4, 'POLYGON((-73.9558697 40.6799803,-73.9465571 40.6799803,-73.9465571 40.6813062,-73.9558697 40.6813062,-73.9558697 40.6799803))')
,(5, 'POLYGON((-73.99129986763 40.673135968817746,-73.99138569831848 40.667602457899505,-73.97909045219421 40.66755363075947,-73.97904753684998 40.673135968817746,-73.99129986763 40.673135968817746))')
end_result_polygons(no, wkt);


--check on the map: https://clydedacruz.github.io/openstreetmap-wkt-playground/
select st_aswkt(st_collect(st_collect(coordinates, centro))) as wkt
from end_result_polygons;





-- limit the Brooklyn nodes to the ones within the marked rectangles
create or replace temporary table picked_node as
select 
  erp.no
, erp.coordinates as erp_coord
, erp.centro
, bn.id
, bn.coordinates as brook_coord
, st_distance(centro, brook_coord) as dist_to_centro
from end_result_polygons erp
cross join brooklyn_node bn
where st_covers(erp.coordinates, bn.coordinates)
qualify 1 = row_number() over (partition by bn.id order by erp.no)
;
-- select count(*) as cnt from picked_node; --120


-- From the nominated "central nodes" to the closest points in Brooklyn
create or replace temporary table central_node as
select no, id, brook_coord, dist_to_centro
from picked_node
qualify dist_to_centro = min(dist_to_centro) over (partition by no)
order by no
;


-- Rectangles with central nodes: https://clydedacruz.github.io/openstreetmap-wkt-playground/
-- Points are matched to the closest central node
with matched_node as (
    select 
      cn.id as central_id
    , pn.id as node_id
    , cn.no
    , cn.brook_coord as central_coord
    , pn.brook_coord
    , st_distance(cn.brook_coord, pn.brook_coord) as dist_to_central
    from central_node cn
    cross join picked_node pn
    where st_dwithin(cn.brook_coord, pn.brook_coord, 750)
    qualify dist_to_central = min(dist_to_central) over (partition by pn.id)
)
, rect as (
    select 
      central_id
    , st_collect( any_value(central_coord),   st_envelope(st_collect(brook_coord))) as rectangle
    from matched_node 
    group by central_id
)
select st_aswkt(st_collect(rectangle)) from rect
;
