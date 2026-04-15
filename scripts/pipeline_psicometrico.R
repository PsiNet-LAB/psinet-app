db_pass <- Sys.getenv("SUPABASE_DB_PASS")



con <- dbConnect(RPostgres::Postgres(),

dbname = "postgres",

host = "db.su-proyecto.supabase.co",

port = 5432,

user = "postgres",

password = db_pass) # Uso seguro de la credencial