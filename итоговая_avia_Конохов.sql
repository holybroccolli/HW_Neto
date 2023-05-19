SET search_path = bookings    --��������� ����� bookings - �� ���������

-- 1. � ����� ������� ������ ������ ���������?
/* ������ �� ������� airports ��������� �� ���� city, ��� ������ ��������� ������������ ������� count �� ���� city.
 * ��������� �������� having � �������� ����� �����������. � �������� ����� �������� ��� ������, ��� ��������� ���� �������� ������ 1.
*/
select city , count(city)
from airports a 							
group by city							
having count(city) >1


--��� ��������� �����������, ����
select city , count(city)
from airports_data ad  							
group by city							
having count(city) >1

-- 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? -���������

/*� ������� ���������� �� ������������� �� �������� ��������� ������ (range) ������� � ����������
 * ��������� ����� ������� ������ ������ (Boeing 777-333 / 11 100).
 * ����� ������ ����������� (inner join) ������� ������ (flights) � ����������� ���������� �� ���� aircraft_code.
 * �� ���� ��������� (airport_code / departure_airport) ����������� ������� � ���������� ���������� (airports).
 * ������������� ����� ���� ������ � �� arrival_airport, ��� ��� ���� ���������, � ������� ������ ���� ����� ��������.
 * ��� ��� ����/�������� ���������� �����������, ��� ������ ��������� �������� DISTINCT ��� ����� ���������� ��������
 * ���������� ���� ���������� �������� "���������" */
 

select distinct ap.airport_name as "���������" 
from 		(select * from aircrafts ac 
			order by "range" desc
			limit 1
			) t
inner join flights f using(aircraft_code)
join airports ap on ap.airport_code = f.departure_airport 
order by 1



-- 3. ������� 10 ������ � ������������ �������� �������� ������ -�������� LIMIT
/*�� ������� ������ flights ������ ������������� ����� flight_id � ����������� ���� - ������� 
 * ����� ����������� � �������� �������� ������ (actual_departure - scheduled_departure).
 * �������� is not null �� ����������� ���� �������� �����, ������� �� ���������� ��� �����������.
 * �������� �� �������� ������� (order by) � ������������ ����������� �� ��������� ���������� ������� (limit 10)
 */

select flight_id , (actual_departure - scheduled_departure) as max_delay 
from flights f 
where (actual_departure-scheduled_departure) is not null
order by 2 desc
limit 10



-- 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������ -������ ��� JOIN
/*������� � �������������� (bookings) ������ � �������� ������� (tickets) �� ������ ������������ ���
 * ����, ����� ����� ������������ ����� ������� � ����������� �������� (boarding_passes)
 * � ������ ������� ������ ��� ���������� ������� ����� ����������� ������ ����� null.
 * ������� ������� bp.boarding_no is null �������� � ������� ������ ����� ��� ��. � select ��������� ���������� ������ � ������� count.
 * ���� ������� ����� �������, �� ���������� ������ � ���������� ���������� ������� ���������/
 */


select count(*) "���������� ������ ��� ����������"
from bookings b 
join tickets t using(book_ref)
left join boarding_passes bp using(ticket_no)
where bp.boarding_no is null

			

	



-- 5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������
--� ������� ���. -������� �������, ���������� �/��� ���

/*
 *��������� ���, � ������� �� ������� flights, ����������� (join) � �������� boarding_passes,
 *���������� ���� (flight_id), ��� �������� (aircraft_code), �������� ����������� (departure_airport), 
 *����������� ���� � ����� ������ (actual_departure), � �����  � ���������� (��������� count) �������� 
 *���������� �������, �.�. ����������� ���������� �����.
 *� ������� ��� ���������� ����� �� �������� Arrived ��� Departed, ��� ��� � ��������� ������� 
 *����������� ���������� � �������� �� ������ ������ ����� ���� ��������. ����������� �� flight_id.
 *
 *� �������� ������� ��������� ��������� � ��������� from ��� �������� ����������� ����� � ������� ������ ��������.
 *������ ��� � ���������� ���������� �� ���� �������� (aircraft_code).
 *� select �������� flight_id, departure_airport, actual_departure � ���� ������ date, ����������� ���������� �����.
 *� ������� ������� ������� ��������� ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����.
 *�����: �����������, ��������� ����� �� ������ ����� � ���������� ��������� � ������ ���������� ���� � ��������.
 */
select * from flights

with cte as (
		select f.flight_id , 
		f.aircraft_code ,
		f.departure_airport ,
		f.actual_departure ,
		count(boarding_no) as actual_fill 
		from flights f
		join boarding_passes bp using(flight_id) 
		where status = 'Arrived' or status = 'Departed'
		group by flight_id 
				)
select 	flight_id,
		cte.departure_airport, cte.actual_departure::date,
		actual_fill, 
		sum(actual_fill) over (partition by cte.departure_airport, cte.actual_departure::date order by cte.actual_departure) as cumulative,
		capacity, 
		(capacity-actual_fill) as "vacant, pc", 
		round((capacity-actual_fill)*100.0/capacity, 2) /*|| '%'*/ as "vacant,%"		
from (	select s.aircraft_code , count (s.seat_no) as capacity
		from seats s 
		group by s.aircraft_code 
		) uq
join cte using (aircraft_code)


-- 6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. -��������� ��� ����. �������� ROUND
/*� �������� ������� ������� aircrafts ������ � �������� ������ flights �� ���� ���� ��������. ��������� ��������� �� ������ � ���� ��������.
 * � ��������� select ��� ������ ���������� � ������� ���������� ��������� ���������� ������ � �������� �������������: status = 'Arrived'.
 * ��� �������� ����������� ����������� �������� �������� round - ���������� �� ���� ���������� ������.  
 */


select	a.model,
		count(f.flight_id ) as "by_type", 
			(select count(flight_id)
			from flights f
			where status = 'Arrived') as total,
		round(count(f.flight_id )*100.0/(select count(flight_id)
										from flights f
										where status = 'Arrived'),2) as "by_type/total"
from aircrafts a
join flights f using(aircraft_code)
group by a.model , f.aircraft_code 
			
			
-- 7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������? -CTE




-- 8. ����� ������ �������� ��� ������ ������? -- ��������� ������������ � ����������� FROM
--�������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)/  - �������� EXCEPT

/* ��� �������� ������ (flights) ������ ������������� � ��������, ����� �������� ���������� ������ �����:
 * - ��� ��� � flights ��� �������� �������, � ������� ��������� ���������, ���������� ��. 
 * - ���������� distinct �������� ���������.
 * �����, �����-����� ������� airports, ������� ������������ ��������� �������.
 * �������� �� ������� ������ ��� ������ ���������.
 * �� ����� � select ������ ��� ���� � ��������, ��� ��� �������� except �������� � ����������� ��������� (�� �����).
 * �� ���������� ������� �������� ��������� ���������� ����� ������������� routes_t, �.�. ������, ����� �������� ���������� �����. 
 */ 

create view routes_t as
select distinct	
		a.city as departure,
		a2.city as arrival
from flights f
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport  

--drop view routes_t 

select 	a1.city as point_A,
		a2.city as point_B
from airports a1
cross join airports a2
where a1.city <> a2.city 
except
select *
from routes_t

--��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ��������� 
--� ���������, ������������� ��� ����� *.  -

/** - � �������� ���� ���������� ��������� � ������� airports_data.coordinates - ���������, ��� � ��������. � ��������� ���� ���������� ��������� � �������� airports.longitude � airports.latitude.
���������� ���������� ����� ����� ������� A � B �� ������ ����������� (���� ������� �� �� �����) ������������ ������������:
d = arccos {sin(latitude_a)�sin(latitude_b) + cos(latitude_a)�cos(latitude_b)�cos(longitude_a - longitude_b)}, ��� latitude_a � latitude_b � ������, longitude_a, longitude_b � ������� ������ �������, d � ���������� ����� �������� ���������� � �������� ������ ���� �������� ����� ������� ����.
���������� ����� ��������, ���������� � ����������, ������������ �� �������:
L = d�R, ��� R = 6371 �� � ������� ������ ������� ����.*/
--- �����
/*
 * � ������� ������ ������ ������� � ����������� ��� ����� �������� � ����� ���������� ������� � ������.
 * ��� ��� ������ ������� �������� �� ������ ���������� � ��� ������� � ��������� ��, �� ���������� ��� ������� ���������� ����� ����������� ��������� �� �������� ������� airports.
 * � �������� case ��� ������� ����� �������� ����� ���������� ������ ������ �������� �� ����� (range) � ������������ ���������� ����� �����������.
 * � ����������� �� ���������� (������ ��� ������ ����) ������ ������� � ��������.
 * 
 */

select distinct 
	a1.airport_name as departure,
	a2.airport_name as arrival,
	a.range as max_distance,
	round((acos(sind(a1.coordinates[0]) * sind(a2.coordinates[0]) + cosd(a1.coordinates[0]) * cosd(a2.coordinates[0]) * cosd(a1.coordinates[1]-a2.coordinates[1])) * 6371)::decimal, 2) as distance,
	case when 
		(a.range - round((acos(sind(a1.coordinates[0]) * sind(a2.coordinates[0]) + cosd(a1.coordinates[0]) * cosd(a2.coordinates[0]) * cosd(a1.coordinates[1]-a2.coordinates[1])) * 6371)::decimal, 2))<0
		then 'Nope'
		else 'Yep'
		end  "Check"
from flights f
join airports a1 on f.departure_airport = a1.airport_code
join airports a2 on f.arrival_airport = a2.airport_code
join aircrafts a on a.aircraft_code = f.aircraft_code 



