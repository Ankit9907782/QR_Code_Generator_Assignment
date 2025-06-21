/*
--
THE TITLE OF PROJECT : QR Code Generator with Scan Logs
AUTHOR : Ankit Ghosh
DATABASE : MySQL 8.0+
------
DESCRIPTION :
Design and implement a MySQL-only solution to generate and manage QR codes, as well
 as log and analyze scan activity. No frontend or backend code is required; focus exclusively on database schema, tables, views, triggers, and procedures for analyzing and reporting.
 -----
FEATURES:
1.User management
2.QR code metadata & status tracking
3.Scan logging with location & device info
4.Triggers for audit trail
5.Views for scan count and top QR codes
6.Stored procedures for Soft Deletion
7.Stored procedures for Scheduled Cleanup
*/


-- Creating datadase named QR_Code_Generator
CREATE DATABASE QR_Code_Generator;

-- Store everything that's why we are using "use"
USE QR_Code_Generator;

-- Creating table for users                     
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY, -- A Primary Key is a single field or combination of fields that uniquely defines a record.
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
); 

-- Creating QR_Codes table which stores each QR code that was generated.                    
CREATE TABLE QR_Codes(
	QR_id INT AUTO_INCREMENT PRIMARY KEY, 
    code VARCHAR(255) NOT NULL UNIQUE, -- e.g., QR_ABC123                 
	created_by INT NOT NULL,
    status ENUM('active', 'expired', 'disabled') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (created_by) REFERENCES users(user_id)  -- A foreign key is a column or group of columns in a relational database table that provides a link between data in two tables.               
);  

-- Creating scan_logs table which logs each time when someone scans a QR code.
CREATE TABLE scan_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    QR_id INT NOT NULL,
    scan_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_type VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (QR_id) REFERENCES QR_codes(QR_id) -- A foreign key is a column or group of columns in a relational database table that provides a link between data in two tables.
); 

-- Creating audit_trail table which keeps a history log of changes made to each QR code like status updated.             
CREATE TABLE audit_trail (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    QR_id INT NOT NULL,
    action VARCHAR(50), -- e.g., 'created', 'status_changed'
    old_status ENUM('active', 'expired', 'disabled'),
    new_status ENUM('active', 'expired', 'disabled'),
    action_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (QR_id) REFERENCES QR_codes(QR_id)
);

-- Now, it's time to insert the sample data for demonstration in each tables.
INSERT INTO users (name, email) VALUES -- Inserting into users table
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com');		
		
INSERT INTO QR_codes (code, created_by, status) VALUES -- Inserting into QR_Codes table
('QR_001', 1, 'active'),
('QR_002', 1, 'disabled'),
('QR_003', 2, 'active');  

INSERT INTO scan_logs (QR_id, ip_address, device_type, country, city) VALUES -- Inserting into scan_logs table
(1, '192.168.0.1', 'Android', 'India', 'Delhi'),
(1, '192.168.0.2', 'iPhone', 'India', 'Mumbai'),
(3, '192.168.0.3', 'Laptop', 'USA', 'New York'); 

INSERT INTO audit_trail (QR_id, action, old_status, new_status) VALUES -- Inserting into audit_trail table
(2, 'status_changed', 'active', 'disabled'); 

-- Now it's time to view the data
SELECT * FROM users;
SELECT * FROM QR_codes;
SELECT * FROM scan_logs;
SELECT * FROM audit_trail;  
               
-- Creating view which counts how many times each QR code has been scanned.      
CREATE VIEW QR_Scan_Counts AS
SELECT 
    q.qr_id,
    q.code,
    COUNT(s.log_id) AS total_scans
FROM 
    qr_codes q
LEFT JOIN 
    scan_logs s ON q.qr_id = s.qr_id AND s.is_deleted = FALSE
WHERE 
    q.is_deleted = FALSE -- Implementing the condition.
GROUP BY 
    q.qr_id;
    
-- To view real time count with each QR code get scanned and stored in the view.
SELECT * FROM QR_Scan_Counts;  
  
-- Query to list top QR codes with the most scanned.
SELECT 
    q.code,
    COUNT(s.log_id) AS scan_count
FROM 
    qr_codes q
JOIN 
    scan_logs s ON q.qr_id = s.qr_id
WHERE 
    s.is_deleted = FALSE
GROUP BY 
    q.qr_id
ORDER BY 
    scan_count DESC
LIMIT 5;

-- Query to identify QR codes that have not been scanned.
SELECT 
    q.qr_id,
    q.code
FROM 
    QR_Codes q
LEFT JOIN 
    scan_logs s ON q.qr_id = s.qr_id AND s.scan_time >= NOW() - INTERVAL 30 DAY
WHERE 
    s.log_id IS NULL
    AND q.is_deleted = FALSE;
      

-- Creating a trigger which keeps a history of changes (creation, status updates) on QR codes.
DELIMITER $$

CREATE TRIGGER trigger_QR_Status_Change
BEFORE UPDATE ON QR_codes
FOR EACH ROW
BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO audit_trail (QR_id, action, old_status, new_status)
        VALUES (OLD.QR_id, 'status_changed', OLD.status, NEW.status);
    END IF;
END$$

DELIMITER ;

-- Qurey to view current QR code status.
SELECT qr_id, code, status FROM qr_codes WHERE qr_id = 1;

-- Update the QR code status.
UPDATE qr_codes SET status = 'disabled' WHERE qr_id = 1;

-- Check the trigger is working or not in audit trail.
SELECT * FROM audit_trail WHERE qr_id = 1 ORDER BY action_time DESC;

-- Creating procedure for Scheduled Cleanup.
DELIMITER $$

CREATE PROCEDURE Scheduled_Cleanup_ArchORExpired_QRs_and_logs() -- A stored procedure is a pre-compiled collection of SQL statements that can accept input parameters, perform complex operations, and return results.
BEGIN
    -- To archive or delete expired QR codes.
    UPDATE qr_codes
    SET is_deleted = TRUE
    WHERE status = 'expired';

   -- To archive or delete functionality for old scan logs.
    UPDATE scan_logs
    SET is_deleted = TRUE
    WHERE scan_time < NOW() - INTERVAL 90 DAY;
END$$

DELIMITER ;

-- Inserting the manula data into QR_Codes for testing PROCEDURE Scheduled_Cleanup_ArchORExpired_QRs_and_logs()
INSERT INTO QR_Codes (code, created_by, status, created_at, is_deleted)
VALUES ('QR_004', 1, 'expired', NOW(), FALSE);

-- To view the data whose status is 'expired'.
SELECT qr_id, code, status, is_deleted
FROM qr_codes
WHERE status = 'expired';

-- Inserting the manula data into scan_logs for testing PROCEDURE Scheduled_Cleanup_ArchORExpired_QRs_and_logs()
INSERT INTO scan_logs (qr_id, scan_time, ip_address, device_type)
VALUES (1, NOW() - INTERVAL 100 DAY, '127.0.0.1', 'TestDevice');

-- Calling the Procedure.
CALL Scheduled_Cleanup_ArchORExpired_QRs_and_logs();

-- After calling the Scheduled_Cleanup_ArchORExpired_QRs_and_logs(), to view the QR code status.
SELECT * FROM qr_codes WHERE status = 'expired';

-- After calling the Scheduled_Cleanup_ArchORExpired_QRs_and_logs(), to view the is_deleted.
SELECT log_id, qr_id, scan_time, is_deleted
FROM scan_logs
WHERE scan_time < NOW() - INTERVAL 90 DAY;

-- Creating procedure for Soft Deletion.

DELIMITER $$

CREATE PROCEDURE Soft_Delete_QR(IN qr INT)
BEGIN
    UPDATE qr_codes SET is_deleted = TRUE WHERE qr_id = qr;
    UPDATE scan_logs SET is_deleted = TRUE WHERE qr_id = qr;
END$$

DELIMITER ;

CALL soft_delete_qr(1);

-- To view the QR code status.
SELECT qr_id, code, is_deleted FROM qr_codes WHERE qr_id = 1;

-- To view the related scan logs
SELECT log_id, qr_id, is_deleted FROM scan_logs WHERE qr_id = 1;
SET SQL_SAFE_UPDATES = 0;

 