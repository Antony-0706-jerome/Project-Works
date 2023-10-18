-- Loading the data

create table IPL_Ball (id bigint , innings int , over int , ball int , batsman varchar(50) , non_striker varchar(50) ,
					  bowler varchar(50) , batsman_runs int , extra_runs int , total_runs int , is_wicket int , 
					  dismissal_kind varchar(50) , player_dismissed varchar(50) , fielder varchar(50) , 
					  extras_type varchar(50) , batting_team varchar(60) , bowling_team varchar(60))
					  
copy ipl_ball from 'C:\Program Files\PostgreSQL\15\data\Data_copy\IPL_Ball.csv'
delimiter ',' csv header

create table IPL_matches (id bigint , city varchar(40) , date date , player_of_match varchar(50) , 
						  venue varchar(80) , neutral_venue int , team1 varchar(70) , team2 varchar(70) , 
						  toss_winner varchar(70) , toss_decision varchar(10) ,	winner varchar(70) , result varchar(10) ,
						  result_margin int , eliminator varchar(3) , method varchar(5) , umpire1 varchar(30) ,	
						  umpire2 varchar(70))
						  
copy IPL_matches from 'C:\Program Files\PostgreSQL\15\data\Data_copy\IPL_matches.csv'
delimiter ','  csv header

--Batsman bidding (Aggressive batsman)

select batsman , sum(batsman_runs) as Total_runs , count(ball) as No_of_balls_faced , 
sum(batsman_runs)/count(ball) as Strike_rate from ipl_ball where extras_type != 'wides'
group by batsman having count(ball) >= 500 order by Strike_rate desc , No_of_balls_faced desc
limit 10

--Batsman bidding (Anchor batsman)

select a.batsman , cast((a.batsman_runs / b.is_wicket)as float) as Average , 
count(distinct extract(year from date)) as Total_season_played 
from 
(select batsman , sum(batsman_runs) as batsman_runs from ipl_ball group by batsman) a
inner join 
(select b.batsman , date , count(is_wicket) as is_wicket from ipl_ball b left join ipl_matches m 
on b.id = m.id where is_wicket = 1 group by b.batsman , date) b 
on a.batsman = b.batsman
group by a.batsman , Average having count(extract(year from date)) > 2
order by Average desc , Total_season_played desc limit 10

--Batsman bidding (hard hitter)

select a.batsman ,
(ROUND((CAST(b.Boundry_runs AS decimal) / CAST(a.total_runs AS decimal)) * 100, 2)) Boundry_Percentage , 
b.Total_seasons_played 
from
(select batsman , sum(batsman_runs) as total_runs from ipl_ball group by batsman) a
inner join 
(select batsman , count(batsman_runs) as Boundries_Count , sum(batsman_runs) as Boundry_runs ,
count(distinct extract(year from date)) as Total_seasons_played
from ipl_matches m left join ipl_ball b 
on m.id = b.id where batsman_runs in (4 , 6)
group by b.batsman) b 
on a.batsman = b.batsman where b.Total_seasons_played > 2
order by Boundry_Percentage desc limit 10

--Bowlers bidding (Economical Bowler)

select a.bowler , b.Total_over , a.Total_runs_conceded , (a.Total_runs_conceded / b.Total_over) Economy from 
(select bowler , sum(total_runs) Total_runs_conceded from ipl_ball group by bowler) a
inner join
(select bowler , count(ball) Total_balls_bowled , count(over) Total_over from ipl_ball group by bowler) b
on a.bowler = b.bowler
where b.Total_balls_bowled >= 500 
order by economy desc , total_runs_conceded asc limit 10

--Bowlers bidding(wicket taking)

select a.bowler , (a.Total_balls_bowled/b.Total_Wicket_taken) Strike_rate from
(select bowler , count(ball) Total_balls_bowled from ipl_ball group by bowler)a
left join
(select bowler , count(is_wicket) Total_Wicket_taken from ipl_ball where is_wicket = 1 group by bowler)b 
on a.bowler = b.bowler where a.Total_balls_bowled >= 500 order by Strike_rate desc limit 10

--All-rounder

with batsman_strike as (select batsman , sum(batsman_runs) as Total_runs , count(ball) as No_of_balls_faced , 
sum(batsman_runs)/count(ball) as Strike_rate from ipl_ball where extras_type != 'wides'
group by batsman having count(ball) >= 500 order by Strike_rate desc , No_of_balls_faced desc
),

bowler_strike as (select a.bowler , (a.Total_balls_bowled/b.Total_Wicket_taken) Strike_rate from
(select bowler , count(ball) Total_balls_bowled from ipl_ball group by bowler)a
left join
(select bowler , count(is_wicket) Total_Wicket_taken from ipl_ball where is_wicket = 1 group by bowler)b 
on a.bowler = b.bowler where a.Total_balls_bowled >= 500 order by Strike_rate desc)

select bat.batsman as all_rounder , bat.strike_rate as Batting_strike , bow.strike_rate as Bowling_strike
from batsman_strike bat inner join bowler_strike bow on bat.batsman = bow.bowler 
order by Batting_strike desc , Bowling_strike desc limit 10

--wicketkeeper

with batsman_strike as (select batsman , sum(batsman_runs) as Total_runs , count(ball) as No_of_balls_faced , 
sum(batsman_runs)/count(ball) as Strike_rate from ipl_ball where extras_type != 'wides'
group by batsman having count(ball) >= 500 order by Strike_rate desc , No_of_balls_faced desc
) ,

man_of_match as (select extract(year from date) as year , max(player_of_match) Player_name
				 from ipl_matches group by year)

(select distinct m_m.Player_name from batsman_strike bs full join man_of_match m_m on bs.batsman = m_m.Player_name
where m_m.Player_name is not null)

