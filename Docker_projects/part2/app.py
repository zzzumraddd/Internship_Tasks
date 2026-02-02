from flask import Flask
import psycopg2
import os

app = Flask(__name__)

@app.route('/hello')
def hello():
    return "Hello AnyOps!\n"

@app.route('/db')
def db_test():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            database=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD')
        )
        cursor = conn.cursor()
        cursor.execute('SELECT version()')
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return f"Database connected! {version}\n"
    except Exception as e:
        return f"Database error: {e}\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)