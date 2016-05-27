SELECT "id","account_type","created_at","updated_at","accountable_id","accountable_type"
UNION SELECT 
id,
account_type,
created_at,
updated_at,
IFNULL(accountable_id,''),
accountable_type
FROM accounts 
INTO OUTFILE '/tmp/zohoreports_accounts.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id","total","comment","account_id","created_at"
UNION SELECT id,total,replace(comment,'\r\n',';'),account_id,created_at FROM transactions 
INTO OUTFILE '/tmp/zohoreports_transactions.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT 
	"id",
	"name",
	"paid",
	"team_id",
	"invoice_id",
	"invoiced_budget",
	"allocatable_budget",
	"created_at",
	"updated_at",
	"parent_id",
	"free_budget",
	"completed",
	"internal_order",
	"commission"
UNION 
SELECT 
	id,
	IFNULL(name,''),
	paid,
	IFNULL(team_id,''),
	IFNULL(invoice_id,''),
	IFNULL(invoiced_budget,''),
	IFNULL(allocatable_budget,''),
	created_at,
	updated_at,
	IFNULL(parent_id,''),
	IFNULL(free_budget,''),
	completed,
	internal_order,
	IFNULL(commission,'')
FROM orders 
INTO OUTFILE '/tmp/zohoreports_orders.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id","name","created_at","updated_at","default_commission"
UNION SELECT id,name,created_at,updated_at, IFNULL(default_commission,'') FROM teams 
INTO OUTFILE '/tmp/zohoreports_teams.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id","name","login","team_id","daily_rate","created_at","updated_at","role_id","active"
UNION SELECT id,name,login,team_id,daily_rate,created_at,updated_at,role_id,active FROM users 
INTO OUTFILE '/tmp/zohoreports_users.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id","external_id","paid","created_at","updated_at"
UNION SELECT id,external_id,paid,created_at,updated_at FROM invoices 
INTO OUTFILE '/tmp/zohoreports_invoices.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id", "external_id","accepted","budget","review_requested","expenses","paid","created_at","updated_at"
UNION SELECT id, external_id,accepted,budget,review_requested,expenses,paid,created_at,updated_at FROM tasks
INTO OUTFILE '/tmp/zohoreports_tasks.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT "id","task_id","order_id","budget","created_at","updated_at"
UNION SELECT id,task_id,order_id,budget,created_at,updated_at FROM task_orders
INTO OUTFILE '/tmp/zohoreports_taskorders.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

# Redmine export - TBD
# 
# SELECT "external_id","name"
# UNION SELECT CONCAT('opsway_',id),subject FROM issues 
# INTO OUTFILE '/tmp/redmine_issues.csv' FIELDS ESCAPED BY '"'  TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

