--use Superstore

--select * from credit_card_transcations

--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

----Using Window Function
with cte as 
(select city, SUM(cast(amount as bigint)) Spend
from credit_card_transcations
group by city
),
cte1 as 
(select city,Spend,
DENSE_RANK() over (order by Spend desc) RankN
from cte 
),
cte2 as 
(select SUM(cast(amount as bigint)) as total_spent
from credit_card_transcations
)
select city,Spend,RankN,total_spent,CAST((cte1.spend*1.0/cte2.total_spent)*100 as decimal (5,2)) percentage_contribution
from cte1
cross join cte2
where RankN<6;

--Without using Window Function

with cte as 
(select SUM(cast(amount as bigint)) total_spend from credit_card_transcations)
select top 5  city,SUM(amount) expense,total_spend,CAST((SUM(amount)*1.0/total_spend)*100 as decimal (5,2)) percentage_contribution
from credit_card_transcations
cross join cte
group by city,total_spend
order by expense desc


-----write a query to print highest spend month and amount spent in that month for each card type
with cte as 
(
select card_type,DATEPART(YEAR,transaction_date) YO,
DATENAME(MONTH,transaction_date) MO,
SUM(amount) Expe
from credit_card_transcations
group by card_type,DATEPART(YEAR,transaction_date),
DATENAME(MONTH,transaction_date)
)
select * from (
select *,RANK() over (partition by card_type order by Expe desc) RN 
from cte) A
where RN=1;


---write a query to print the transaction details(all columns from the table) for each card type when
---it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

select * 
from credit_card_transcations

select * from 
(select *,
rank() over (partition by card_type order by Cumm_sum) rn
from (
(
select *,
sum(amount) over (partition by card_type order by transaction_date,transaction_id) Cumm_sum
from credit_card_transcations
)) A )b
where rn=1


--write a query to find city which had lowest percentage spend for gold card type, only gold expense

with City_spnd as 
(select SUM(cast(amount as bigint)) total_spend from credit_card_transcations where card_type ='gold')
select city,SUM(amount) Spend,cast((SUM(amount)*1.0/total_spend)*100 as decimal (7,3)) perc_total,total_spend
from credit_card_transcations,City_spnd
where card_type ='gold'
group by city,total_spend
order by perc_total;


-- write a query to find city which had lowest percentage spend for gold card type, among all expenses


select city,SUM(amount) spend,
SUM(case when card_type ='Gold' then amount else 0 end) Gold_spend,
(SUM(case when card_type ='Gold' then amount else 0 end)*1.0/SUM(amount)*100)as Gold_contri
from credit_card_transcations
group by city
having SUM(case when card_type ='Gold' then amount else 0 end)>0
order by Gold_contri

--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with total_spend as 
(
select city,exp_type,sum(amount) Spend
from credit_card_transcations
group by city,exp_type
),
rankas as
(select *,
rank () over (partition by city order by Spend) Lowest_spend,
rank () over (partition by city order by Spend desc) Highest_spend
from total_spend
)
select city,
max(case when Highest_spend=1 then exp_type end) High_spend,
max(case when Lowest_spend=1 then exp_type end) low_spend
from rankas
where Lowest_spend=1 or Highest_spend=1
group by city;


--write a query to find percentage contribution of spends by females for each expense type

with cte as 
(select SUM(cast(amount as bigint)) total_spend from credit_card_transcations)
select exp_type,SUM(amount) Spend,total_spend,cast(SUM(amount)*1.0/total_spend*100 as decimal(5,2)) Percentage_total
from credit_card_transcations,cte
where gender ='F'
group by exp_type,total_spend;


--which card and expense type combination saw highest month over month growth in Jan-2014

with MoM_Spend as
(
select datepart(MONTH,transaction_date) Month_,card_type,exp_type,SUM(amount) Spend
from credit_card_transcations
where transaction_date like '%2014%'
group by card_type,exp_type,datepart(MONTH,transaction_date)
),
Prev_Month_spend as
(select *,
LAG(Spend,1) over (partition by card_type,exp_type order by Month_) PV_Mo
from MoM_Spend
)
select top 1 *,cast((Spend-Prev_Month_spend.PV_Mo)*1.0/Prev_Month_spend.PV_Mo*100 as decimal(5,2)) Perc_
from Prev_Month_spend
order by Perc_ desc;

--which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as 
(
select *,
ROW_NUMBER() over (partition by city order by transaction_date,transaction_id) RN
from credit_card_transcations)
select city,
MIN(transaction_date) First_date,
MAX(transaction_date) last_date,
DATEDIFF(DAY,MIN(transaction_date),max(transaction_date)) Diff_
from cte 
where RN in (1,500)
group by city
having COUNT(*)=2
order by Diff_



