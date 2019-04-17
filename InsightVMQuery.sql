WITH asset_ips AS (
              SELECT asset_id, ip_address, type
              FROM dim_asset_ip_address dips
              ),
			  
solutions AS (
			SELECT * 
			FROM dim_solution

),

vuln_solutions AS ( select * from dim_vulnerability_solution),

asset_addresses AS (
                    SELECT da.asset_id,
                    (SELECT array_to_string(array_agg(ip_address), ',') FROM asset_ips WHERE asset_id = da.asset_id AND type = 'IPv4') AS ipv4s,
                    (SELECT array_to_string(array_agg(ip_address), ',') FROM asset_ips WHERE asset_id = da.asset_id AND type = 'IPv6') AS ipv6s,
                    (SELECT array_to_string(array_agg(mac_address), ',') FROM dim_asset_mac_address WHERE asset_id = da.asset_id) AS macs
                    FROM dim_asset da
                    JOIN asset_ips USING (asset_id)
                    ),
asset_names AS (
                SELECT asset_id, array_to_string(array_agg(host_name), ',') AS names
                FROM dim_asset_host_name
                GROUP BY asset_id
                ),
asset_facts AS (
                SELECT asset_id, riskscore, exploits, malware_kits
                FROM fact_asset
                ),
vulnerability_metadata AS (
                           SELECT *
                           FROM dim_vulnerability dv
                           ),
vuln_cves_ids AS (
                  SELECT DISTINCT ON(1) vulnerability_id, array_to_string(array_agg(reference), ',') AS cves
                  FROM dim_vulnerability_reference
                  GROUP BY vulnerability_id
				  HAVING COUNT(*) = 1
                  )


SELECT 
da.ip_address AS "Asset IP Address",
--favi.port AS "Service Port",
--dp.name AS "Service Protocol",
--dsvc.name AS "Service Name",
an.names AS "Asset Names",
dag.name AS "Asset Group",
favi.date AS "Vulnerability Test Date",
--dsc.started AS "Last Scan Time",
--favi.scan_id AS "Scan ID",
--ds.name AS "Site Name",
--ds.importance AS "Site Importance",
vm.date_published AS "Vulnerability Published Date",
vm.date_modified AS "Vulnerability Date Modified",
--ROUND((EXTRACT(epoch FROM age(now(), date_published)) / (60 * 60 * 24))::numeric, 0) AS "Vulnerability Age",
--cves.cves AS "Vulnerability CVE IDs",
vm.nexpose_id AS "Vulnerability ID",
vm.title AS "Vulnerability Title",
vm.cvss_score AS "Vulnerability CVSS Score",
proofAsText(vm.description) AS "Vulnerability Description",
vm.severity AS "Severity Level",
dvs.description AS "Vulnerability Test Result Description",
s.summary as "Fix Summary",
favi.proof AS "Proof"


FROM fact_asset_vulnerability_instance favi
JOIN dim_asset da USING (asset_id)
LEFT OUTER JOIN asset_addresses aa USING (asset_id)
LEFT OUTER JOIN asset_names an USING (asset_id)
JOIN asset_facts af USING (asset_id)
JOIN dim_service dsvc USING (service_id)
JOIN dim_protocol dp USING (protocol_id)
JOIN dim_site_asset dsa USING (asset_id)
JOIN dim_asset_group_asset USING (asset_id)
JOIN dim_asset_group dag USING (asset_group_id)
JOIN dim_site ds USING (site_id)
JOIN vulnerability_metadata vm USING (vulnerability_id)
JOIN dim_vulnerability_status dvs USING (status_id)
JOIN dim_operating_system dos USING (operating_system_id)
JOIN vuln_solutions USING (vulnerability_id)
JOIN solutions s USING (solution_id)

--LEFT OUTER JOIN dim_scan dsc USING (scan_id)
LEFT OUTER JOIN vuln_cves_ids cves USING (vulnerability_id)
