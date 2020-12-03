
CREATE OR REPLACE FUNCTION iconic.sp_cls_insert()
  RETURNS integer AS
$BODY$
DECLARE 
lv_v_stg                             VARCHAR;
lv_v_rec_cnt                         INTEGER;
/*
Function : iconic.cls_insert
Purpose  : This function will be called to load data from staging to clean staging
*/
BEGIN

    lv_v_stg:= 'Get the record count from the staging table' ; 
    RAISE notice 'Get the record count from the staging table' ; 
	
	select count(1) into lv_v_rec_cnt from iconic.stg_EcommTrans;
	
    lv_v_stg := 'No of records in staging table';
    RAISE NOTICE 'No of records in staging table : %', lv_v_rec_cnt;	
	
	If lv_v_rec_cnt  <> 0 then
	
      lv_v_stg:= 'Data exist in staging table and ingest the data into clean staging' ; 
      RAISE notice 'Data exist in staging table and ingest the data into clean staging' ; 	
	
 insert into iconic.cls_EcommTrans
 select CAST(customer_id               AS varchar),
       case when CAST(days_since_first_order AS integer) > CAST(days_since_last_order AS integer) then  CAST(days_since_first_order AS integer)
            else CAST(days_since_last_order AS integer) 
       end as days_since_first_order,
       case when CAST(days_since_last_order AS integer) > CAST(days_since_first_order AS integer) then  CAST(days_since_first_order AS integer)
            else CAST(days_since_last_order AS integer) 
       end as days_since_last_order,
 CAST(is_newsletter_subscriber  AS varchar),
 CAST(orders                    AS integer),
 CAST(items                     AS integer),
 CAST(cancels                   AS integer),
 CAST(returns                   AS integer),
 CAST(different_addresses       AS integer),
 CAST(shipping_addresses        AS integer),
 CAST(devices                   AS integer),
 CAST(vouchers                  AS integer),
 CAST(cc_payments               AS integer),
 CAST(paypal_payments           AS integer),
 CAST(afterpay_payments         AS integer),
 CAST(apple_payments            AS integer),
 CAST(female_items              AS integer),
 CAST(male_items                AS integer),
 CAST(unisex_items              AS integer),
 CAST(wapp_items                AS integer),
 CAST(wftw_items                AS integer),
 CAST(mapp_items                AS integer),
 CAST(wacc_items                AS integer),
 CAST(macc_items                AS integer),
 CAST(mftw_items                AS integer),
 CAST(wspt_items                AS integer),
 CAST(mspt_items                AS integer),
 CAST(curvy_items               AS integer),
 CAST(sacc_items                AS integer),
 CAST(msite_orders              AS integer),
 CAST(desktop_orders            AS integer),
 CAST(android_orders            AS integer),
 CAST(ios_orders                AS integer),
 CAST(other_device_orders       AS integer),
 CAST(work_orders               AS integer),
 CAST(home_orders               AS integer),
 CAST(parcelpoint_orders        AS integer),
 CAST(other_collection_orders   AS integer),
 CAST(average_discount_onoffer/10000  AS float  ),
 CAST(average_discount_used     AS float  ),
 CAST(revenue                   AS float  )
 from iconic.stg_EcommTrans;

    else   

       lv_v_stg:= 'Data is not exist in staging table' ; 
       RAISE notice 'Data is not exist in staging table' ; 
    
       RETURN 1;
    end if; 
    
	lv_v_stg:= 'Truncate the data from staging table' ; 
    RAISE notice 'Truncate the data from staging table' ; 
	
	Truncate iconic.stg_EcommTrans;	

 RETURN 0;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;