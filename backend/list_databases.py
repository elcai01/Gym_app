import psycopg2

def main():
    try:
        conn = psycopg2.connect("postgresql://postgres:C4m3r1c4@localhost:5432/postgres")
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
            dbs = cur.fetchall()
            print("Databases:")
            for db in dbs:
                print(f" - {db[0]}")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
