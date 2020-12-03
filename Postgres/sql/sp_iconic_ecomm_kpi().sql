CREATE OR REPLACE FUNCTION iconic.sp_iconic_ecomm_kpi()
  RETURNS TABLE(Total_Revenue  integer,Female_Percentage integer,Ios_Andriod_Desk_Avg_Revenue decimal) AS
$BODY$
DECLARE 
lv_v_stg                              VARCHAR;
lv_cc_revenue                         INTEGER;
lv_Female_Percentage                  INTEGER;
lv_ios_Ios_Andriod_Desk_Avg_Revenue   DECIMAL; 
lv_v_insert_date                      DATE;

BEGIN

    lv_v_stg:= 'Execute the total revenue, female percentage catalog, and order type metrics query' ; 
    RAISE notice 'Execute the total revenue, female percentage catalog, and order type metrics query' ; 
    
   SELECT t1.cc_revenue
         ,t2.Female_Percentage 
         ,t3.ios_Ios_Andriod_Desk_Avg_Revenue
   INTO   lv_cc_revenue
         ,lv_Female_Percentage
         ,lv_ios_Ios_Andriod_Desk_Avg_Revenue
   from 
       /*What was the total revenue to the nearest dollar for customers who have paid by credit card?*/
	   (select round(sum(revenue))  as cc_revenue 
         from iconic.cls_EcommTrans where cc_payments > 0
		) t1
   cross join 
        /*What percentage of customers who have purchased female items have paid by credit card?*/  
       (select round((sum(CASE WHEN female_items > 0 and cc_payments > 0 THEN 1 ELSE 0 END)* 100 )
                            /(select count(distinct customer_id) from iconic.cls_EcommTrans where female_items> 0)
						   ) as Female_Percentage
               from iconic.cls_EcommTrans
			   ) t2
   cross join 
        /*What was the average revenue for customers who used either iOS, Android or Desktop?*/
        (select avg(revenue) from iconic.cls_ecommtrans  where  (desktop_orders > 0 or android_orders > 0 or ios_orders > 0) 
		 )t3;

    lv_v_stg:= 'Get the last insert date from the kpi metrics table' ; 
    RAISE notice 'Get the last insert date from the kpi metrics table' ; 
    
    select cast(max(insert_ts) as date) into lv_v_insert_date from iconic.kpi_agg;

    lv_v_stg := 'Max insert date from kpi metrics table';
    RAISE NOTICE 'Max insert date : %', lv_v_insert_date;
    
    If lv_v_insert_date = cast(current_timestamp AT time zone 'Australia/Sydney' as date) then

       lv_v_stg:= 'Delete the existing entry for the current day' ; 
       RAISE notice 'Delete the existing entry for the current day' ; 
    
       delete from iconic.kpi_agg where cast(insert_ts as date) = lv_v_insert_date;

       lv_v_stg:= 'Populate the latest enrty for the current day' ; 
       RAISE notice 'Populate the latest enrty for the current day' ; 
    
       insert into iconic.kpi_agg(Total_Revenue,Female_Percentage,Ios_Andriod_Desk_Avg_Revenue) values (lv_cc_revenue,lv_Female_Percentage,lv_ios_Ios_Andriod_Desk_Avg_Revenue);
    else   

       lv_v_stg:= 'Insert the kpi metrics for the current day' ; 
       RAISE notice 'Insert the kpi metrics for the current day' ; 
    
       insert into iconic.kpi_agg(Total_Revenue,Female_Percentage,Ios_Andriod_Desk_Avg_Revenue) values (lv_cc_revenue,lv_Female_Percentage,lv_ios_Ios_Andriod_Desk_Avg_Revenue);
    end if;

    lv_v_stg:= 'Return the kpi metrics as a function' ; 
    RAISE notice 'Return the kpi metrics as a function' ; 
    
    RETURN QUERY select lv_cc_revenue,lv_Female_Percentage,lv_ios_Ios_Andriod_Desk_Avg_Revenue;


END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100