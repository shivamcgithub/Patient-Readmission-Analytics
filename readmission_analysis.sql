/* ============================================================================
   PATIENT READMISSION ANALYTICS
   Identifying High-Risk Patients for Proactive Care
   Author: Shivam Chaudhary | ReadmitGuard Analytics (Simulated)
   Table: patient_encounters
   ============================================================================ */


/* ----------------------------------------------------------------------------
   1. OVERALL 30-DAY READMISSION RATE
   Baseline KPI for the executive summary.
---------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                                   AS total_encounters,
    SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) AS total_readmissions,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters;


/* ----------------------------------------------------------------------------
   2. READMISSION RATE BY PRIMARY DIAGNOSIS
   Identifies which conditions drive the most readmissions -> prioritization list.
---------------------------------------------------------------------------- */
SELECT
    primary_diagnosis,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)  AS readmissions,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY primary_diagnosis
ORDER BY readmission_rate_pct DESC;


/* ----------------------------------------------------------------------------
   3. READMISSION RATE BY AGE GROUP
   Buckets patients into clinically meaningful age bands.
---------------------------------------------------------------------------- */
SELECT
    CASE
        WHEN age < 40 THEN 'Under 40'
        WHEN age BETWEEN 40 AND 59 THEN '40-59'
        WHEN age BETWEEN 60 AND 74 THEN '60-74'
        ELSE '75+'
    END AS age_group,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN 'Under 40' THEN 1 WHEN '40-59' THEN 2 WHEN '60-74' THEN 3 ELSE 4
    END;


/* ----------------------------------------------------------------------------
   4. READMISSION RATE BY DISCHARGE DISPOSITION
   Tests whether where a patient is discharged to affects return risk.
---------------------------------------------------------------------------- */
SELECT
    discharge_disposition,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY discharge_disposition
ORDER BY readmission_rate_pct DESC;


/* ----------------------------------------------------------------------------
   5. IMPACT OF FOLLOW-UP APPOINTMENTS ON READMISSION
   Directly tests a proactive-care lever: does scheduling follow-up reduce risk?
---------------------------------------------------------------------------- */
SELECT
    followup_appointment_scheduled,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY followup_appointment_scheduled;


/* ----------------------------------------------------------------------------
   6. PRIOR ADMISSIONS AS A RISK PREDICTOR
   Shows how prior utilization correlates with new readmission -> early flagging.
---------------------------------------------------------------------------- */
SELECT
    prior_admissions_12mo,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY prior_admissions_12mo
ORDER BY prior_admissions_12mo;


/* ----------------------------------------------------------------------------
   7. LENGTH OF STAY: READMITTED VS NOT READMITTED
   Compares average LOS and medication burden between the two groups.
---------------------------------------------------------------------------- */
SELECT
    readmitted_30_days,
    COUNT(*)                                   AS total_patients,
    ROUND(AVG(length_of_stay_days), 1)          AS avg_length_of_stay,
    ROUND(AVG(num_medications), 1)              AS avg_medications,
    ROUND(AVG(comorbidity_count), 1)            AS avg_comorbidities
FROM patient_encounters
GROUP BY readmitted_30_days;


/* ----------------------------------------------------------------------------
   8. HIGH-RISK PATIENT WATCHLIST
   Business rule: flag currently-discharged patients likely to be high-risk
   for a 30-day readmission based on >=2 prior admissions in the last 12 months,
   >=3 comorbidities, and no scheduled follow-up appointment.
   -> This is the list ReadmitGuard hands to care managers for proactive outreach.
---------------------------------------------------------------------------- */
SELECT
    patient_id,
    patient_name,
    age,
    primary_diagnosis,
    prior_admissions_12mo,
    comorbidity_count,
    followup_appointment_scheduled,
    discharge_disposition,
    discharge_date
FROM patient_encounters
WHERE prior_admissions_12mo >= 2
  AND comorbidity_count >= 3
  AND followup_appointment_scheduled = 'No'
ORDER BY prior_admissions_12mo DESC, comorbidity_count DESC;


/* ----------------------------------------------------------------------------
   9. TOP READMISSION REASONS (among readmitted patients only)
   Root-cause breakdown -> informs which interventions to design.
---------------------------------------------------------------------------- */
SELECT
    readmission_reason,
    COUNT(*) AS occurrences,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patient_encounters WHERE readmitted_30_days = 'Yes'), 1) AS pct_of_readmissions
FROM patient_encounters
WHERE readmitted_30_days = 'Yes'
GROUP BY readmission_reason
ORDER BY occurrences DESC;


/* ----------------------------------------------------------------------------
   10. READMISSION RATE BY INSURANCE TYPE
   Supports resource-planning / payer-mix discussion in the BRD cost-benefit case.
---------------------------------------------------------------------------- */
SELECT
    insurance_type,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM patient_encounters
GROUP BY insurance_type
ORDER BY readmission_rate_pct DESC;
