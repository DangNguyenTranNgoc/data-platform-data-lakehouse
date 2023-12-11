/*
    SAMPLE SQL QUERY TO TEST TRINO CONNECT MINIO
*/
-- Create bucket and insert data into Hive table
CREATE SCHEMA IF NOT EXISTS hive.iris
WITH (location = 's3a://iris/');

CREATE TABLE IF NOT EXISTS hive.iris.iris_parquet
(
    sepal_length DOUBLE,
    sepal_width  DOUBLE,
    petal_length DOUBLE,
    petal_width  DOUBLE,
    class        VARCHAR
)WITH (format = 'PARQUET');

insert into hive.iris.iris_parquet (
    select random() as sepal_length, 
           random() as sepal_width, 
           random() as petal_length, 
           random() as petal_widths, 
           cast(random(1, 3) as varchar) as class 
    from unnest(sequence(1,10)));

-- Create bucket and insert data into Delta Lake table
CREATE SCHEMA IF NOT EXISTS mydelta.deltairis
    WITH (location = 's3a://iris/');

CREATE TABLE IF NOT EXISTS mydelta.deltairis.deltairis_parquet
(
    sepal_length DOUBLE,
    sepal_width  DOUBLE,
    petal_length DOUBLE,
    petal_width  DOUBLE,
    class        VARCHAR
);

insert into mydelta.deltairis.deltairis_parquet (
    select random() as sepal_length, 
           random() as sepal_width, 
           random() as petal_length, 
           random() as petal_widths, 
           cast(random(1, 3) as varchar) as class
    from unnest(sequence(1,10)));
