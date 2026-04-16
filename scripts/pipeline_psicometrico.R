# ==============================================================================
# PIPELINE DE REDES INTRA-SUJETO (GGM) - PsiNet LAB
# ==============================================================================
library(DBI)
library(RPostgres)
library(jsonlite)
library(bootnet)
library(qgraph)

# 1. Conexión segura
db_pass <- Sys.getenv("SUPABASE_DB_PASS")
con <- dbConnect(RPostgres::Postgres(),
                 dbname   = "postgres",
                 host     = "db.xbckuaveoqpxguadhcki.supabase.co", 
                 port     = 5432,
                 user     = "postgres",
                 password = db_pass)