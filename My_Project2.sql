select * from employee_demographics;

select * from employee_salary;

select * from parks_departments;



-- Estimate future leadership pipeline by identifying employees under age 35 with above-average salaries—potential future leaders.
with employee_summary as
(
select es.first_name, es.last_name, ed.age, pd.department_name, salary, avg(salary) as avg_salary
from employee_demographics as ed
join employee_salary as es on ed.employee_id = es.employee_id
join parks_departments as pd on es.dept_id = pd.department_id 
group by first_name, last_name, age, department_name, salary
), salary_summary as
(
select first_name, last_name, age, department_name, salary, avg(salary) over(partition by department_name ) as salary_avg
from employee_summary
), rank_by_salary_summary as
(
select first_name, last_name, age, department_name, salary, salary_avg, 
rank() over(partition by department_name order by salary desc) as rank_by_salary
from salary_summary
) 
select * from rank_by_salary_summary;




-- Identify departments where average salary is lower than the overall average. Suggest potential budget reallocation or pay structure updates.
with dept_summary as 
(
select department_name, avg(salary) as avg_department_salary
from employee_salary as es
join parks_departments as pd
on es.dept_id = pd.department_id
group by department_name
), 
avg_dept_salary as
(
select department_name, avg_department_salary, avg(avg_department_salary) over() as overall_dept_salary
from dept_summary
)
select * from avg_dept_salary
where avg_department_salary < overall_dept_salary;

-- Compare average salaries across age brackets (20–29, 30–39, etc.). Visualize trends and discuss any patterns or anomalies.
select 
case
when age between 20 and 29 then '20-29'
when age between 30 and 39 then '30-39'
when age between 40 and 49 then '40-49'
when age between 50 and 59 then '50-59'
else '60+'
end as age_bracket, avg(salary) as avg_salary
from employee_demographics as ed
join employee_salary as es on ed.employee_id = es.employee_id
join parks_departments as pd on es.dept_id = pd.department_id
group by age_bracket;



-- For each department, calculate the percentage distribution of male and female employees. Identify departments with skewed ratios.
with dept_summary as
(
	select department_name, gender, count(gender) as num_of_gender
	from employee_demographics as ed
	join employee_salary as es on ed.employee_id = es.employee_id
	join parks_departments as pd on es.dept_id = pd.department_id
	group by department_name, gender
), 
total_dep_summary as
(
	select department_name, gender, num_of_gender, sum(num_of_gender) over(partition by department_name) as total_per_department
	from dept_summary
), 
g_percent_summary as
(
	select department_name, gender, num_of_gender, total_per_department,
	case 
		when num_of_gender > 0
		then round((num_of_gender / total_per_department) * 100, 2)
		end as gender_percent
	from total_dep_summary
)select * from g_percent_summary;


-- Identify employees nearing retirement age (e.g., 60+), grouped by department, and flag departments at higher risk.
with dept_summary as
( 
select department_name,count(es.dept_id) as total_employees, 
	SUM(case 
		when TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) >= 60 
		then 1 ELSE 0
	end) AS num_60_plus
from employee_demographics as ed
join employee_salary as es on ed.employee_id = es.employee_id
join parks_departments as pd on es.dept_id = pd.department_id
group by department_name
), rank_summary as 
(
select department_name, total_employees, num_60_plus, 
	case
		when total_employees > 0
		then round(((num_60_plus * 100.0) / total_employees ),2)
	end as percent_60_plus
from dept_summary
), risk_summary as 
(
select department_name, total_employees, num_60_plus, percent_60_plus,
	case
    when percent_60_plus >= 50 then 'High Risk'
	when percent_60_plus >= 30 then 'Medium Risk'
    else 'Low Risk'
	end as risk_flag
from rank_summary
) select * from risk_summary;



-- Departmental Salary Rankings: Ranked departments by total and average salary spend.
with department_summary as 
(
select department_name, sum(salary) as total_salary, avg(salary) as avg_salary
from employee_salary as es
join parks_departments as pd
on es.dept_id = pd.department_id
group by department_name
), ranking_summary as
(
select department_name, total_salary, avg_salary, 
rank() over(order by avg_salary desc) as rank_by_avg_salary, 
rank() over(order by total_salary desc) as rank_by_total_salary
from department_summary
) select * from ranking_summary;

-- Tenure Estimation: Estimated years of experience using birth dates (if start dates were present).
select first_name, last_name, age, year(current_date()) -  year(birth_date) - 22 as work_experience
from employee_demographics;


-- Age Distribution by Department: Analyzed how age varies across departments.
select pd.department_name,
case
when age between 20 and 30 then '19-29'
when age between 31 and 40 then '31-40'
when age between 41 and 50 then '41-50'
else '50+'
end as age_bracket, count(ed.employee_id) as employee_count
from employee_demographics as ed
join employee_salary as es on ed.employee_id = es.employee_id
join parks_departments as pd on es.dept_id = pd.department_id
group by department_name, age_bracket;


-- Birth Month Trends: Found common birth months for team celebrations.
select date_format(birth_date, '%m') as birth_month, count(es.employee_id) as employee
from employee_salary as es
join employee_demographics as ed
on es.employee_id = ed.employee_id
group by date_format(birth_date, '%m')
order by birth_month desc;


-- Missing Data Check: Identified employees without department IDs (data cleanup).
select first_name, last_name
from employee_salary
where dept_id is null;


-- Gender Pay Gap: Compared average salary between genders.
select gender, avg(salary) as avg_salary
from employee_salary as es
join employee_demographics as ed 
on es.employee_id = ed.employee_id
group by gender;


-- Salary Distribution Tiers: Categorized employees into salary tiers (e.g., Low, Mid, High).
select first_name, last_name, salary,
case
 when salary >= 90000 then 'Top earners'
 when salary >= 60000 then 'Mid level Professionals'
 else 'Entry level'
end as Tier
from employee_salary;


-- Department Headcount Analysis: Counted number of employees in each department.
select department_name, count(dept_id) as number_of_employees
from parks_departments as pd
join employee_salary as es
on pd.department_id = es.dept_id
group by department_name;

-- Top Earners by Role: Ranked employees within each occupation by salary using window functions.
select first_name, last_name, occupation, salary, rank() over(order by salary desc) as rank_by_salary
from employee_salary;


-- Employee Salary Insights: Analyzed average salaries by department and gender.
select department_name, gender, avg(salary) as avg_salary
from employee_salary as es
join parks_departments as pd on es.dept_id = pd.department_id
join employee_demographics as ed on es.employee_id = ed.employee_id 
group by department_name, gender
order by gender;
