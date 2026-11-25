SELECT m.barcode, m.commercial_name AS name,
    m.package_qty, m.measure_unit,
    m.package_qty || ' ' || m.measure_unit AS packaging, -- Joins the package qty with the unit so it outputs '20 tablets'
    m.unit_price AS price,
    (SELECT GROUP_CONCAT(composition, ', ')
     FROM (
         SELECT mc.substance_name || ' ' || mc.content || ' ' || mc.content_unit AS composition
         FROM Medicine_Composition mc
         WHERE mc.barcode = m.barcode
         ORDER BY mc.substance_name
     )) AS active_substances,
    MAX(0,
        COALESCE((SELECT SUM(b.available_qty) FROM Batch b
                    WHERE b.med_id = m.barcode
                    AND date(b.exp_date) >= date('now', 'localtime')), 0) -- all the ones that are not expired
        - COALESCE((SELECT SUM(MAX(t.reserved_qty, t.pending_qty))
                    FROM Order_Item_Totals t
                    WHERE t.medicine_id = m.barcode), 0) -- all the ones that are not reserved
    ) AS available -- Available are: (not_expired - reserved) = available
FROM Medicine m
WHERE m.commercial_name LIKE ? -- pattern from python goes here
OR CAST(m.barcode AS TEXT) LIKE ? -- pattern from python goes here
ORDER BY m.commercial_name, m.barcode;
