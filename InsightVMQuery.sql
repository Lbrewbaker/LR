WITH remediations AS (
    SELECT DISTINCT fr.solution_id AS ultimate_soln_id, summary, fix, estimate, riskscore, dshs.solution_id AS solution_id
    FROM fact_remediation(10,'riskscore DESC') fr
    JOIN dim_solution ds USING (solution_id)
    JOIN dim_solution_highest_supercedence dshs ON (fr.solution_id = dshs.superceding_solution_id AND ds.solution_id = dshs.superceding_solution_id)

),


assets AS (
    SELECT DISTINCT asset_id, host_name, ip_address, dos.description
    FROM dim_asset
	JOIN dim_operating_system dos USING (operating_system_id)
    GROUP BY asset_id, host_name, ip_address, dos.description

),

vuln_meta AS (  
	SELECT *
    FROM dim_vulnerability dv
)

SELECT DISTINCT

	ast.ip_address AS "Asset IP Address",
	ast.host_name AS "Asset Hostname", 
	dag.name AS "Asset Group",
	ast.description AS "Asset OS",
	favi.date AS "Vulnerability Test Date",
	vm.date_published AS "Vulnerability Published Date",
	vm.date_modified AS "Vulnerability Date Modified",
	csv(DISTINCT vm.title) AS "Vulnerability Title",
	--round(sum(vm.riskscore)) AS "Asset Risk",
	vm.nexpose_id AS "Vulnerability ID",
	vm.title AS "Vulnerability Title",
	vm.cvss_score AS "Vulnerability CVSS Score",
	proofAsText(vm.description) AS "Vulnerability Description",
	vm.severity AS "Severity Level", 
	summary AS "Fix Summary",
	favi.proof AS "Proof"


FROM remediations r
	JOIN dim_asset_vulnerability_solution dvs USING (solution_id)
	JOIN vuln_meta vm USING (vulnerability_id)
	JOIN fact_asset_vulnerability_instance favi USING (asset_id)
	JOIN assets ast USING (asset_id)
	JOIN dim_asset_group_asset USING (asset_id)
	JOIN dim_asset_group dag USING (asset_group_id)



GROUP BY vm.title, r.riskscore, ast.host_name, ast.ip_address, ast.asset_id, summary, fix, vm.nexpose_id, vm.cvss_score, vm.description, vm.severity, vm.date_modified, vm.date_published, dag.name, favi.date, favi.proof, ast.description

-- Wish list: 
-- Written by Luke Brewbaker - CGI Group - Senior Consultant - Security Engineer
