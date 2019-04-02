WITH remediations AS (
    SELECT DISTINCT fr.solution_id AS ultimate_soln_id, summary, fix, estimate, riskscore, dshs.solution_id AS solution_id
    FROM fact_remediation(10,'riskscore DESC') fr
    JOIN dim_solution ds USING (solution_id)
    JOIN dim_solution_highest_supercedence dshs ON (fr.solution_id = dshs.superceding_solution_id AND ds.solution_id = dshs.superceding_solution_id)

),

assets AS (
	SELECT da.asset_id, da.host_name, da.ip_address, dos.description
	FROM dim_asset da
	JOIN dim_operating_system dos ON dos.operating_system_id = da.operating_system_id
	JOIN fact_asset fa ON fa.asset_id = da.asset_id
	GROUP BY da.asset_id, da.host_name, da.ip_address, dos.description
)

SELECT
   dv.title AS "Vulnerability Title",
   dv.nexpose_id AS "Vulerability ID",
   dv.date_published AS "Date Published",
   dv.riskscore	AS "Vulerability Risk Score",
   a.host_name AS "Asset Hostname", 
   a.ip_address AS "Asset IP", 
   a.description AS "OS",
   round(sum(dv.riskscore)) AS "Asset Risk Score",
   r.summary AS "Solution",
   r.fix as "Fix",
   sol.solution_type AS "Type",
   sol.additional_data AS "Additional Data",
   fav.proof AS "Proof"

   
FROM remediations r
   JOIN dim_asset_vulnerability_solution dvs USING (solution_id)
   JOIN dim_solution sol USING (solution_id)
   JOIN dim_vulnerability dv USING (vulnerability_id)
   JOIN assets AS a USING (asset_id)
   JOIN fact_asset_vulnerability_instance fav USING (vulnerability_id)

GROUP BY r.riskscore,dv.title, dv.nexpose_id, dv.date_published, dv.riskscore, a.host_name, a.ip_address, a.asset_id, r.summary, r.fix, a.description, sol.additional_data, sol.solution_type