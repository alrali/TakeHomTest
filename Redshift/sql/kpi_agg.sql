CREATE TABLE public.kpi_agg
(
	total_revenue INTEGER ENCODE az64,
	female_percentage INTEGER ENCODE az64,
	ios_andriod_desk_avg_revenue NUMERIC(14, 2) ENCODE az64,
	inert_ts TIMESTAMP DEFAULT convert_timezone(('UTC'::character varying)::text, ('AUSTRALIA/NSW'::character varying)::text, getdate()) ENCODE az64
)
DISTSTYLE EVEN;