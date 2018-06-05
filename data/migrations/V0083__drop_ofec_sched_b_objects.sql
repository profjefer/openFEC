
-- ------------------
-- 	functions and triggers
-- ------------------
DROP TRIGGER nml_sched_b_after_trigger ON disclosure.nml_sched_b;
DROP TRIGGER nml_sched_b_before_trigger ON disclosure.nml_sched_b;

DROP TRIGGER f_item_sched_b_before_trigger ON disclosure.f_item_receipt_or_exp;
DROP TRIGGER f_item_sched_b_after_trigger ON disclosure.f_item_receipt_or_exp;

drop function public.ofec_sched_b_delete_update_queues();
drop function public.ofec_sched_b_insert_update_queues();

drop function public.ofec_sched_b_update_queues();
drop function public.ofec_sched_b_update_fulltext();
drop function public.ofec_sched_b_update();

-- ------------------
-- 	tables
-- ------------------
drop table if exists public.ofec_sched_b_queue_new;
drop table if exists public.ofec_sched_b_queue_old;
drop table if exists public.ofec_sched_b_fulltext;
drop table if exists public.ofec_sched_b_1977_1978;
drop table if exists public.ofec_sched_b_1979_1980;
drop table if exists public.ofec_sched_b_1981_1982;
drop table if exists public.ofec_sched_b_1983_1984;
drop table if exists public.ofec_sched_b_1985_1986;
drop table if exists public.ofec_sched_b_1987_1988;
drop table if exists public.ofec_sched_b_1989_1990;
drop table if exists public.ofec_sched_b_1991_1992;
drop table if exists public.ofec_sched_b_1993_1994;
drop table if exists public.ofec_sched_b_1995_1996;
drop table if exists public.ofec_sched_b_1997_1998;
drop table if exists public.ofec_sched_b_1999_2000;
drop table if exists public.ofec_sched_b_2001_2002;
drop table if exists public.ofec_sched_b_2003_2004;
drop table if exists public.ofec_sched_b_2005_2006;
drop table if exists public.ofec_sched_b_2007_2008;
drop table if exists public.ofec_sched_b_2009_2010;
drop table if exists public.ofec_sched_b_2011_2012;
drop table if exists public.ofec_sched_b_2013_2014;
drop table if exists public.ofec_sched_b_2015_2016;
drop table if exists public.ofec_sched_b_2017_2018;
drop table if exists public.ofec_sched_b_master;



