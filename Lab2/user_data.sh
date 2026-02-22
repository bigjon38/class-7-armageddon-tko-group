#!/bin/bash
yum update -y
yum install -y python3 python3-pip

# Create app directory
mkdir -p /opt/rdsapp

# Install Flask
pip3 install flask pymysql boto3

# Create the Flask app
cat > /opt/rdsapp/app.py << 'APPEOF'
from flask import Flask
import pymysql
import boto3
import json
import os

app = Flask(__name__)

def get_secret():
    client = boto3.client('secretsmanager', region_name='us-east-1')
    secret = client.get_secret_value(SecretId='kamau/rds/mysql')
    return json.loads(secret['SecretString'])

def get_param(name):
    client = boto3.client('ssm', region_name='us-east-1')
    return client.get_parameter(Name=name)['Parameter']['Value']

@app.route('/')
def home():
    return 'OK', 200

@app.route('/health')
def health():
    return 'healthy', 200

@app.route('/list')
def list_records():
    try:
        secret = get_secret()
        endpoint = get_param('/kamau/app/db/endpoint')
        db = pymysql.connect(
            host=endpoint,
            user=secret['username'],
            password=secret['password'],
            database='kamau_db'
        )
        cursor = db.cursor()
        cursor.execute('SHOW TABLES')
        tables = cursor.fetchall()
        db.close()
        return str(tables), 200
    except Exception as e:
        return f'ERROR: {str(e)}', 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
APPEOF

# Create systemd service
cat > /etc/systemd/system/flask-app.service << 'SVCEOF'
[Unit]
Description=Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/rdsapp
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

# Start the service
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app