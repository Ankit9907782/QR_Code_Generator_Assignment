# QR Code Generator with Scan Logs (MySQL-only Assignment)

## 📌 Description
This project is a SQL-only implementation of a QR Code management system.  
It supports generating and managing QR codes, logging scans, and analyzing scan activity.

## 📁 Features
- QR code metadata table
- Scan logs with IP, device, and optional location
- Real-time scan count tracking
- Audit trail via triggers
- Soft delete implementation
- Scheduled cleanup procedure
- Views for top scanned and inactive QR codes

## ⚙️ Tech Used
- MySQL 8.0+
- SQL Stored Procedures, Triggers, Views
- No frontend/backend involved

## ▶️ How to Test
1. Open `QR_Code_Generator_Assignment.sql` in MySQL Workbench
2. Run the full file to create schema, tables, sample data, and procedures
3. Call sample procedures or queries to see results
