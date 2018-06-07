/*
Addresses #3196

Fix doubled totals for off-year special election candidates

TODO: Ask DBA team about optimization
*/

SET search_path = public;

DROP MATERIALIZED VIEW IF EXISTS ofec_candidate_totals_mv_TMP;

CREATE MATERIALIZED VIEW ofec_candidate_totals_mv_TMP AS
 WITH totals AS (
         SELECT ofec_totals_house_senate_mv.committee_id,
            ofec_totals_house_senate_mv.cycle,
            ofec_totals_house_senate_mv.receipts,
            ofec_totals_house_senate_mv.disbursements,
            ofec_totals_house_senate_mv.last_cash_on_hand_end_period,
            ofec_totals_house_senate_mv.last_debts_owed_by_committee,
            ofec_totals_house_senate_mv.coverage_start_date,
            ofec_totals_house_senate_mv.coverage_end_date,
            false AS federal_funds_flag
           FROM ofec_totals_house_senate_mv
        UNION ALL
         SELECT ofec_totals_presidential_mv.committee_id,
            ofec_totals_presidential_mv.cycle,
            ofec_totals_presidential_mv.receipts,
            ofec_totals_presidential_mv.disbursements,
            ofec_totals_presidential_mv.last_cash_on_hand_end_period,
            ofec_totals_presidential_mv.last_debts_owed_by_committee,
            ofec_totals_presidential_mv.coverage_start_date,
            ofec_totals_presidential_mv.coverage_end_date,
            ofec_totals_presidential_mv.federal_funds_flag
           FROM ofec_totals_presidential_mv
 ), cycle_totals AS (
         SELECT DISTINCT ON (link.cand_id, totals.cycle) link.cand_id AS candidate_id,
            max(election.cand_election_year) AS election_year,
            totals.cycle,
            false AS is_election,
            sum(totals.receipts) AS receipts,
            sum(totals.disbursements) AS disbursements,
            (sum(totals.receipts) > (0)::numeric) AS has_raised_funds,
            sum(totals.last_cash_on_hand_end_period) AS cash_on_hand_end_period,
            sum(totals.last_debts_owed_by_committee) AS debts_owed_by_committee,
            min(totals.coverage_start_date) AS coverage_start_date,
            max(totals.coverage_end_date) AS coverage_end_date,
            (array_agg(totals.federal_funds_flag) @> ARRAY[true]) AS federal_funds_flag
           FROM (select distinct cand_id, fec_election_yr, cmte_id, cmte_dsgn
                from ofec_cand_cmte_linkage_mv) link
             INNER JOIN totals
                ON link.cmte_id = totals.committee_id
                AND link.fec_election_yr = totals.cycle
             LEFT JOIN ofec_candidate_election_mv election
                ON link.cand_id = election.candidate_id
                AND totals.cycle <= election.cand_election_year
                AND totals.cycle > election.prev_election_year
          WHERE link.cmte_dsgn IN ('P', 'A')
          GROUP BY link.cand_id, election.cand_election_year, totals.cycle
 ), election_aggregates AS (
         SELECT cycle_totals.candidate_id,
            cycle_totals.election_year,
            sum(cycle_totals.receipts) AS receipts,
            sum(cycle_totals.disbursements) AS disbursements,
            (sum(cycle_totals.receipts) > (0)::numeric) AS has_raised_funds,
            min(cycle_totals.coverage_start_date) AS coverage_start_date,
            max(cycle_totals.coverage_end_date) AS coverage_end_date,
            (array_agg(cycle_totals.federal_funds_flag) @> ARRAY[true]) AS federal_funds_flag
           FROM cycle_totals
          GROUP BY cycle_totals.candidate_id, cycle_totals.election_year
 ), election_latest AS (
         SELECT DISTINCT ON (totals.candidate_id, totals.election_year) totals.candidate_id,
            totals.election_year,
            totals.cash_on_hand_end_period,
            totals.debts_owed_by_committee,
            totals.federal_funds_flag
           FROM cycle_totals totals
          ORDER BY totals.candidate_id, totals.election_year, totals.cycle DESC
 ), election_totals AS (
         SELECT totals.candidate_id,
            totals.election_year,
            totals.election_year AS cycle,
            true AS is_election,
            totals.receipts,
            totals.disbursements,
            totals.has_raised_funds,
            latest.cash_on_hand_end_period,
            latest.debts_owed_by_committee,
            totals.coverage_start_date,
            totals.coverage_end_date,
            totals.federal_funds_flag
           FROM (election_aggregates totals
             JOIN election_latest latest USING (candidate_id, election_year))
 )
 SELECT cycle_totals.candidate_id,
    cycle_totals.election_year,
    cycle_totals.cycle,
    cycle_totals.is_election,
    cycle_totals.receipts,
    cycle_totals.disbursements,
    cycle_totals.has_raised_funds,
    cycle_totals.cash_on_hand_end_period,
    cycle_totals.debts_owed_by_committee,
    cycle_totals.coverage_start_date,
    cycle_totals.coverage_end_date,
    cycle_totals.federal_funds_flag
   FROM cycle_totals
UNION ALL
 SELECT election_totals.candidate_id,
    election_totals.election_year,
    election_totals.cycle,
    election_totals.is_election,
    election_totals.receipts,
    election_totals.disbursements,
    election_totals.has_raised_funds,
    election_totals.cash_on_hand_end_period,
    election_totals.debts_owed_by_committee,
    election_totals.coverage_start_date,
    election_totals.coverage_end_date,
    election_totals.federal_funds_flag
   FROM election_totals;

--Permissions

ALTER TABLE ofec_candidate_totals_mv_TMP OWNER TO fec;
GRANT SELECT ON TABLE ofec_candidate_totals_mv_TMP TO fec_read;

--Indexes--------------

/*
Filters on this model for TotalsCandidateView:

- filter_multi_fields = election_year, cycle
- filter_range_fields = receipts, disbursements, cash_on_hand_end_period, debts_owed_by_committee
- filter_match_fields = has_raised_funds, federal_funds_flag, is_election

*/

CREATE UNIQUE INDEX ofec_candidate_totals_mv_candidate_id_cycle_is_election_idx_TMP ON ofec_candidate_totals_mv USING btree (candidate_id, cycle, is_election);

CREATE INDEX ofec_candidate_totals_mv_candidate_id_idx_TMP
    ON ofec_candidate_totals_mv USING btree (candidate_id);

CREATE INDEX ofec_candidate_totals_mv_cycle_candidate_id_idx_TMP
    ON ofec_candidate_totals_mv USING btree (cycle, candidate_id);

CREATE INDEX ofec_candidate_totals_mv_cycle_idx_TMP
    ON ofec_candidate_totals_mv USING btree (cycle);

CREATE INDEX ofec_candidate_totals_mv_receipts_idx_TMP
    ON ofec_candidate_totals_mv USING btree (receipts);

CREATE INDEX ofec_candidate_totals_mv_disbursements_idx_TMP
    ON ofec_candidate_totals_mv USING btree (disbursements);

CREATE INDEX ofec_candidate_totals_mv_election_year_idx_TMP
    ON ofec_candidate_totals_mv USING btree (election_year);

CREATE INDEX ofec_candidate_totals_mv_federal_funds_flag_idx_TMP
    ON ofec_candidate_totals_mv USING btree (federal_funds_flag);

CREATE INDEX ofec_candidate_totals_mv_has_raised_funds_idx_TMP
    ON ofec_candidate_totals_mv USING btree (has_raised_funds);

CREATE INDEX ofec_candidate_totals_mv_is_election_idx_TMP
    ON ofec_candidate_totals_mv USING btree (is_election);


--Rename all

/*TODO: Can't drop the old view because
materialized view ofec_candidate_flag_mv depends on materialized view ofec_candidate_totals_mv
materialized view ofec_candidate_totals_with_0s_mv depends on materialized view ofec_candidate_totals_mv
*/

--DROP MATERIALIZED VIEW IF EXISTS ofec_candidate_totals_mv;

--ALTER MATERIALIZED VIEW IF EXISTS ofec_candidate_totals_mv_TMP RENAME TO ofec_candidate_totals_mv;

--SELECT rename_indexes('ofec_candidate_totals_mv');
