--drop table iconic.kpi_agg
create table iconic.kpi_agg(
      Total_Revenue integer,
	  Female_Percentage integer,
	  Ios_Andriod_Desk_Avg_Revenue decimal(14,2),
	  insert_ts timestamp without time zone DEFAULT timezone('Australia/Sydney'::text, now())
	  )