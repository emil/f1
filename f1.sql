-- create database
--  psql -h 0.0.0.0 -c 'create database f1'
--  create tables
--  psql -h 0.0.0.0 -d f1 -f f1db_postgres.sql
-- CREATE EXTENSION tablefunc;
-- set vars
--  \set months 12
--  \set beginning '2017-01-01'

-- warmup races
select date, name
from races
where date >= date :'beginning'
  and date <   date :'beginning'
  + :months * interval '1 month'
order by date;

-- warmup drivers participating
select drivers.surname
from drivers
where exists (
  select from results
  join races using(race_id)
  where date >= date :'beginning'
  and date < date :'beginning'
  + :months * interval '1 month'
  and results.driver_id = drivers.driver_id)
order by lower(drivers.surname);

--- warmup sample results
select date, name, drivers.surname as driver, position, points
from races
  join results
  on results.race_id = races.race_id
  join drivers using(driver_id)
where date >= date :'beginning'
  and date <  date :'beginning'
  + :months * interval '1 month'
  and results.position is not null limit 20;

--- add running_points
select date, name, drivers.surname as driver,
  results.position as race_position,
  sum(points) over (partition by driver_id order by date) as running_points
from races
  join results
  on results.race_id = races.race_id
  join drivers using(driver_id)
where date >= date :'beginning'
  and date <  date :'beginning'
  + :months * interval '1 month'
  and results.position is not null;

-- add order by running_points
with rr AS
(
select date, name, drivers.surname as driver,
  results.position as race_position,
  sum(points) over (partition by driver_id order by date) as running_points
from races
  join results
  on results.race_id = races.race_id
  join drivers using(driver_id)
where date >= date :'beginning'
  and date <  date :'beginning'
  + :months * interval '1 month'
  and results.position is not null
)
select * from rr order by date, running_points desc;

---- add running position
with rr AS
(
  select date, name, drivers.surname as driver, position, points,
    sum(points) over (partition by driver_id order by date) as total_points
  from races
    join results
    on results.race_id = races.race_id
    join drivers using(driver_id)
  where date >= date :'beginning'
    and date <  date :'beginning'
    + :months * interval '1 month'
    and results.position is not null
)
select driver, name, position, points, total_points,
  rank() over (partition by date order by total_points desc) as current_rank
from rr order by date;

-- crosstab pivot
-- https://www.postgresql.org/docs/current/tablefunc.html
select *
from crosstab(
  $$
  with rr AS
  (
  select date, name, drivers.surname as driver, position, points
  from races
    left join results
    on results.race_id = races.race_id
    left join drivers using(driver_id)
  where date >= '2017-01-01'::date
    and date <  '2017-01-01'::date
    + 12 * interval '1 month'
    and results.position is not null
    )
  select driver::text, name::text, position::bigint
  from rr
  order by 1, date
$$
) AS ct(driver text, AU bigint, CN bigint, BAH bigint, RU bigint, ES bigint,
        MON bigint, CA bigint, AZE bigint, AT bigint, GB bigint, HU bigint,
        BEL bigint, ITA bigint, SG bigint, MAL bigint, JP bigint, US bigint,
        MX bigint, BR bigint, ABD bigint
        );

-- add total points
-- missing rows, create problems
select *
from crosstab(
    $$
    with rr AS
    (
    select date, name, drivers.surname as driver, position, points
    from races
      left join results
      on results.race_id = races.race_id
      left join drivers using(driver_id)
    where date >= '2017-01-01'::date
      and date <  '2017-01-01'::date
      + 12 * interval '1 month'
      and results.position is not null
      )
  select driver::text, name::text, points::bigint from (
    select driver::text, name::text, date as date, points::bigint from rr
    union all
    select driver::text, 'Total' as name, null as date, sum(points::bigint) as points from rr
    group by driver
      ) t
  order by 1, date
    $$
    ) AS ct(driver text, AU bigint, CN bigint, BAH bigint, RU bigint, ES bigint,
            MON bigint, CA bigint, AZE bigint, AT bigint, GB bigint, HU bigint,
            BEL bigint, ITA bigint, SG bigint, MAL bigint, JP bigint, US bigint,
            MX bigint, BR bigint, ABD bigint, Total bigint
            );


-- fix missing rows
-- spell out columns
-- missing rows, create problems
-- add total points
select *
from crosstab(
    $$
    with rr AS
    (
    select date, name, drivers.surname as driver, position, points
    from races
      join results
      on results.race_id = races.race_id
      join drivers using(driver_id)
    where date >= '2017-01-01'::date
      and date <  '2017-01-01'::date
      + 12 * interval '1 month'
      and results.position is not null
      )
  select driver::text, name::text, points::bigint
  from (
    select driver::text, name::text, date as date, points::bigint from rr
    union all
    select driver::text, 'Total' as name, null as date, sum(points::bigint) as points from rr
    group by driver
      ) t
    order by sum(points) over (partition by driver) desc, driver, date
    $$,
    $$
    select name
    from (
      select date, name from races
      where date >= '2017-01-01'::date
        and date <  '2017-01-01'::date
        + 12 * interval '1 month'
      UNION
      select '2017-12-31'::date as date , 'Total' as name
        ) t
      order by date
    $$
    ) AS ct(driver text, AU bigint, CN bigint, BAH bigint, RU bigint, ES bigint,
            MON bigint, CA bigint, AZE bigint, AT bigint, GB bigint, HU bigint,
            BEL bigint, ITA bigint, SG bigint, MAL bigint, JP bigint, US bigint,
            MX bigint, BR bigint, ABD bigint, Total bigint
            );

-- change points to the running total
select *
from crosstab(
    $$
    with rr AS
    (
    select date, name, drivers.surname as driver, position, points
    from races
      join results
      on results.race_id = races.race_id
      join drivers using(driver_id)
    where date >= '2017-01-01'::date
      and date <  '2017-01-01'::date
      + 12 * interval '1 month'
      and results.position is not null
      )
  select driver::text, name::text, points::bigint
  from (
    select driver::text, name::text, date as date,
          sum(points) over (partition by driver order by date) as points from rr
    union all
    select driver::text, 'Total' as name, null as date, sum(points::bigint) as points from rr
    group by driver
      ) t
    order by sum(points) over (partition by driver) desc, driver, date
    $$,
    $$
    select name
    from (
      select date, name from races
      where date >= '2017-01-01'::date
        and date <  '2017-01-01'::date
        + 12 * interval '1 month'
      UNION
      select '2017-12-31'::date as date , 'Total' as name
        ) t
      order by date
    $$
    ) AS ct(driver text, AU bigint, CN bigint, BAH bigint, RU bigint, ES bigint,
            MON bigint, CA bigint, AZE bigint, AT bigint, GB bigint, HU bigint,
            BEL bigint, ITA bigint, SG bigint, MAL bigint, JP bigint, US bigint,
            MX bigint, BR bigint, ABD bigint, Total bigint
            );


 -- export to CSV
copy (select *
from crosstab(
    $$
    with rr AS
    (
    select date, name, drivers.surname as driver, position, points
    from races
      join results
      on results.race_id = races.race_id
      join drivers using(driver_id)
    where date >= '2017-01-01'::date
      and date <  '2017-01-01'::date
      + 12 * interval '1 month'
      and results.position is not null
      )
  select driver::text, name::text, points::bigint
  from (
    select driver::text, name::text, date as date,
          sum(points) over (partition by driver order by date) as points
    from rr
    union all
    select driver::text, 'Total' as name, null as date, sum(points::bigint) as points
    from rr
    group by driver
      ) t
    order by sum(points) over (partition by driver) desc, driver, date
    $$,
    $$
    select name
    from (
      select date, name from races
      where date >= '2017-01-01'::date
        and date <  '2017-01-01'::date
        + 12 * interval '1 month'
      UNION
      select '2017-12-31'::date as date , 'Total' as name
        ) t
      order by date
    $$
    ) AS ct(driver text, AU bigint, CN bigint, BAH bigint, RU bigint, ES bigint,
            MON bigint, CA bigint, AZE bigint, AT bigint, GB bigint, HU bigint,
            BEL bigint, ITA bigint, SG bigint, MAL bigint, JP bigint, US bigint,
            MX bigint, BR bigint, ABD bigint, Total bigint
            )) TO '/Users/emilmarcetta/scratch/f1/F1_2017.csv' WITH (FORMAT CSV);

--- extra
-- where is last_value/finishers lost?
-- https://www.postgresql.org/docs/12/functions-window.html
-- and default RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  with rr AS
  (
  select date, name, drivers.surname as driver,
    rank() over w as race_position,
    last_value(results.position) over w as finishers
  from races
    left join results
    on results.race_id = races.race_id
    left join drivers using(driver_id)
  where date >= date :'beginning'
    and date <   date :'beginning'
    + :months * interval '1 month'
    and results.position is not null
    window w as (
      partition by results.race_id order by results.position asc
      )
    )
select * from rr;

  -- shows total points, no order by
  with rr AS
  (
  select date, name, drivers.surname as driver, position, points,
    sum(points) over (partition by driver_id) as total_points
  from races
    left join results
    on results.race_id = races.race_id
    left join drivers using(driver_id)
  where date >= date :'beginning'
    and date <   date :'beginning'
    + :months * interval '1 month'
    and results.position is not null
    )
select * from rr order by date, total_points desc;


--- order by does it!
--- https://www.postgresql.org/docs/12/functions-window.html
--- explain RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--- and default RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

with rr AS
(
select date, name, drivers.surname as driver, position, points,
sum(points) over (partition by driver_id order by date) as running_points
from races
left join results
on results.race_id = races.race_id
left join drivers using(driver_id)
where date >= date :'beginning'
and date <   date :'beginning'
+ :months * interval '1 month'
and results.position is not null
)
select * from rr order by date, running_points desc;
