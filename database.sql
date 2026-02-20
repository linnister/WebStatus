CREATE DATABASE IF NOT EXISTS webstatus CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE webstatus;

CREATE TABLE IF NOT EXISTS sites (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(2048) NOT NULL,
    host VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    interval_minutes TINYINT UNSIGNED NOT NULL DEFAULT 5,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    allowed_status_codes JSON NULL,
    tags JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sites_active_interval (is_active, interval_minutes),
    INDEX idx_sites_host (host)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS checks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id BIGINT UNSIGNED NULL,
    url VARCHAR(2048) NOT NULL,
    is_up TINYINT(1) NOT NULL,
    http_status SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    response_time_ms INT UNSIGNED NULL,
    error_type VARCHAR(64) NULL,
    error_message VARCHAR(1024) NULL,
    checked_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_checks_site_checked (site_id, checked_at),
    INDEX idx_checks_url_checked (url(255), checked_at),
    CONSTRAINT fk_checks_site FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS incidents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id BIGINT UNSIGNED NOT NULL,
    started_at DATETIME NOT NULL,
    ended_at DATETIME NULL,
    reason_summary VARCHAR(512) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_incidents_site_open (site_id, ended_at),
    INDEX idx_incidents_started (started_at),
    CONSTRAINT fk_incidents_site FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS jobs_queue (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id BIGINT UNSIGNED NOT NULL,
    run_at DATETIME NOT NULL,
    claimed_at DATETIME NULL,
    claim_token VARCHAR(64) NULL,
    attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
    last_error VARCHAR(1024) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_jobs_due (run_at, claimed_at),
    INDEX idx_jobs_claim_token (claim_token),
    CONSTRAINT fk_jobs_site FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_limits (
    `key` VARCHAR(128) NOT NULL,
    window_start DATETIME NOT NULL,
    count INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`key`, window_start)
) ENGINE=InnoDB;

INSERT INTO sites (url, host, display_name, interval_minutes, is_active, allowed_status_codes)
VALUES
('https://example.com', 'example.com', 'Example', 5, 1, JSON_ARRAY(200,301,302)),
('https://cloudflare.com', 'cloudflare.com', 'Cloudflare', 5, 1, JSON_ARRAY(200,301,302));
