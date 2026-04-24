--queries
--query top_10_total_income
SELECT 
-- concatenar nombre y apellido
CONCAT(emp.first_name, ' ', emp.last_name) as seller,
--contar las veces que cada vendedor ha realizado una venta
count(sal.sales_person_id) as operations,
--funcion FLOOR que redondea hacia abajo 
FLOOR(SUM(pro.price * sal.quantity)) as income
--seleccion de tabla primaria para esta query y uniones con su respectivo alias usando las claves primarias de cada tabla
FROM employees as emp
join sales as sal on sal.sales_person_id = emp.employee_id 
join products as pro on sal.product_id = pro.product_id 
-- en orden: clausulas para agrupar resultados por cada vendedor, ordenar de mayor a menor en base a la ganancia y limitar al top 10
group by seller 
order by income desc
limit 10;
--query lowest_average_income.csv
with tab as(
SELECT 
FLOOR(AVG(pro.price * sal.quantity)) as total_ventas_emp --sumatoria de venta total x cada empleado
FROM employees as emp
join sales as sal on sal.sales_person_id = emp.employee_id 
join products as pro on sal.product_id = pro.product_id 
group by emp.employee_id), --agrupar por empleados para poder luego sacar promedio general de total de todos
--floor(avg(total_ventas_emp)) from tab == Promedio es 1214390345
tab2 as(
SELECT 
-- concatenar nombre y apellido
CONCAT(emp.first_name, ' ', emp.last_name) as seller,
--funcion FLOOR que redondea hacia abajo, SUMATORIA de las ventas de cada empleado 
FLOOR(AVG(pro.price * sal.quantity)) as income
--seleccion de tabla primaria para esta query y uniones con su respectivo alias usando las claves primarias de cada tabla
FROM employees as emp
join sales as sal on sal.sales_person_id = emp.employee_id 
join products as pro on sal.product_id = pro.product_id 
-- en orden: clausulas para agrupar resultados por cada vendedor, ordenar de mayor a menor en base a la ganancia y limitar al top 10
group by seller)
--sacar de la tabla temporal 2 todos los vendedores y su total personal
select seller, income as averge_income 
from tab2
--comparar el total personal con el promedio de todos sacado de la CTE1
where income < (select floor(avg(total_ventas_emp)) from tab)
order by averge_income asc; 
--query day_of_the_week_income
SELECT 
CONCAT(emp.first_name, ' ', emp.last_name) as seller, --concatenar nombre
TRIM(TO_CHAR(sal.sale_date,  'Day')) AS day_of_week, -- sacar cada dia de la semana 
FLOOR(SUM(sal.quantity* pro.price)) as incon -- sumar ventas de ese dia
--union de tablas y alias
FROM employees as emp
join sales as sal on sal.sales_person_id = emp.employee_id 
join products as pro on sal.product_id = pro.product_id
group by day_of_week, EXTRACT(ISODOW FROM sal.sale_date), seller  --agrupacion por cada dia de la semana, extraer dias de 1 a 7, vendedor
order by EXTRACT(ISODOW FROM sal.sale_date), seller; --Extrae el número del día según el estándar ISO (donde Lunes es 1 y Domingo es 7)
--sin el ISODOW comienza a contar desde Firday
--segmentar los grupos para luego unirlos, CTE
with gr1 as ( --grupo 1
select age
from customers c
where age >= 16 and age <=25 --filtrado de cada grupo
),
gr2 as ( --grupo 2
select age
from customers c2
where age >= 26 and age <=40
), gr3 as ( --grupo 3
select age
from customers c3
where age > 40
)
--union de las tablas dando la categoria y contando total por grupo
select '16-25' as age_category, count(age) as age_count from gr1
union
select '26-40' as age_category, count(age) as age_count from gr2
union
select '40+' as age_category, count(age) as age_count from gr3
--customers_by_month
select  
TO_CHAR(sal.sale_date,  'YYYY-MM') AS selling_month, --segmentar la fechas usando funcion to char
count(distinct customer_id) as total_customers, --contar total de clientes unicos por mes
sum(sal.quantity * pro.price) as income --sumatoria de las ganancias por mes
from sales as sal
join products as pro on pro.product_id = sal.product_id 
--where sal.customer_id = 4341
group by selling_month
order by selling_month;
--crear cte para sacar la primera aparicion por cliente y fecha de cada compra
WITH primera_aparicion AS (
    SELECT cus.customer_id as pa_id, --guardar el id de cada cliente
    		CONCAT(cus.first_name, ' ', cus.last_name) as customer, --concatenar nombres cliente
    		sal.sale_date as sale_date, --fecha
    		CONCAT(emp.first_name, ' ', emp.last_name) as seller, --concatenar nombres vendedores
    		--utilizar row number que enumera la primera aparicion, damos como parametro cada cliente y la fecha
           ROW_NUMBER() OVER(PARTITION BY sal.customer_id ORDER BY sal.sale_date ASC) as rn
           --uniones -keys
    FROM sales as sal
    join customers as cus on cus.customer_id = sal.customer_id
    join products as pro on pro.product_id = sal.product_id
    join employees as emp on emp.employee_id = sal.sales_person_id
    where pro.price = 0 --filtrar por primera compra que meustre precio en 0
)
--seleccionar los datos luego del filtrado en la CTE
SELECT customer, sale_date, seller
FROM primera_aparicion 
WHERE rn = 1 --indicar que queremos solo el 1er resultado de cada cliente registrado en la cte
order by pa_id; --ordenar por ID del cliente en este caso el alias en la cte
