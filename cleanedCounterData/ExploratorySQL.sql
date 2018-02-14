/*
	Analytic SQLite for assembled DB:
*/
--find most-ridden years; raw.
select SUM(TotalCount)
	, Name
	, strftime(TimestampRecord) as "YEAR"
FROM BIKECOUNT
GROUP BY NAME,strftime(TimestampRecord)
ORDER BY 1 desc;

--explore: http://www.seattleweatherblog.com/rain-stats/rainfall-2017/
--lots of rain!

select distinct name from bikecount;
/*2ndAveCycleTrack
26thAveGreenway
39thAveGreenway
BroadwayCycleTrack
BurkeGilmanTrail70th
ChiefSealthTrailThistle
ElliotBayTrailMyrtlePark
FremontBridge
MTSTrailI90
58thStGreenway22ndAve
SpokaneStBridge*/

SELECT NAME,
COUNT(DISTINCT SUBSTR(TimestampRecord,7,4)) AS "YEAR"
FROM BIKECOUNT
GROUP BY NAME;

--Most have 4 years' data; Fremont has more;
--2ndAve has 3, ChiefSealthTrailThistle has 2
-- This query not handling distinct properly... because of sqlite3?
SELECT NAME
, DISTINCT(SUBSTR(TimestampRecord,7,4)) AS "YEAR"
FROM BIKECOUNT
WHERE NAME IN ('ChiefSealthTrailThistle','2ndAveCycleTrack')
GROUP BY NAME

DROP TABLE IF EXISTS "CLEANBIKECOUNT"
CREATE TABLE IF NOT EXISTS "CLEANBIKECOUNT" (
  "Name" TEXT,
  "TimestampRecord" DATETIME,
  "Latitude" REAL,
  "Longitude" REAL,
  "NB" INT,
  "SB" INT,
  "TotalCount" INT
);

/*cleansing datatype*/
INSERT INTO CLEANBIKECOUNT (Name,Date,Latitude,Longitude,NB,SB,TotalCount)
SELECT Name,Date,Latitude,Longitude,NB,SB,TotalCount FROM BIKECOUNT;

select SUM(TotalCount) as TotalCount
	,  NAME 
	,  strftime("%Y", TimestampRecord) as 'year' 
       from CLEANBIKECOUNT 
       group by strftime("%Y", TimestampRecord), Name
       order by 1 desc;

--sanity checks on dates, sums, handling of zeroes:
--24 hours in a day:
SELECT COUNT(*)
FROM CLEANBIKECOUNT
WHERE NAME = 'SpokaneStBridge'
AND 	strftime('%Y-%m-%d', TimestampRecord) = '2014-01-01';
--actually contains correct counts. should be 246:
SELECT SUM(TotalCount)
FROM CLEANBIKECOUNT
WHERE NAME = 'SpokaneStBridge'
AND 	strftime('%Y-%m-%d', TimestampRecord) = '2014-01-01';
--passes!

--largest bike day for each counter:
SELECT MAX(TotalCount) as LargestCount
	, strftime('%Y-%m-%d', TimestampRecord) as DAY
	, Name
FROM CLEANBIKECOUNT
GROUP BY NAME
ORDER BY NAME;
/*
274|2014-09-29|26thAveGreenway
321|2015-05-15|2ndAveCycleTrack
88|2015-06-10|39thAveGreenway
215|2014-07-12|58thStGreenway22ndAve
112|2017-05-13|BroadwayCycleTrack
866|2017-08-18|BurkeGilmanTrail70th
60|2015-07-30|ChiefSealthTrailThistle
460|2014-05-13|ElliotBayTrailMyrtlePark
1165|2017-06-06|FremontBridge
364|2016-08-14|MTSTrailI90
431|2016-05-02|SpokaneStBridge
*/

--compare total with pandas totalsum:
SELECT SUM(TOTALCOUNT) FROM CLEANBIKECOUNT;
--12195202 --checks out

--run check to determine if there is not >1 day/counter:
SELECT COUNT(*) AS COUNTPERDAY
	, NAME
	, strftime('%Y-%m-%d', TimestampRecord)
FROM CLEANBIKECOUNT
GROUP BY NAME, strftime('%Y-%m-%d', TimestampRecord)
HAVING COUNT(*) > 24;
--explore results - one month for one count has dupes:
select *
from CLEANBIKECOUNT
where name = 'MTSTrailI90'
and strftime('%Y-%m-%d', TimestampRecord) = '2017-10-01'

--source data has duplicate month for one file. 
--in notebook, added dedupe clause on key (name,timestamprecord)

--get average rides/day; assign across all months. many assumptions.
SELECT SUM(TOTALCOUNT)*24.0/count(*) AS AVG
	, NAME
	, strftime('%m',TimestampRecord) as MONTH
FROM CLEANBIKECOUNT
GROUP BY NAME,strftime('%m',TimestampRecord);
