CREATE TABLE logs (
    timestamp DATETIME NOT NULL,
    event ENUM('MESSAGE', 'JOIN', 'PART', 'KICK', 'BAN', 'ME', 'UNBAN') NOT NULL DEFAULT 'MESSAGE',
    user VARCHAR(255) NOT NULL,
    log_line TEXT,
    ban_time INT,
    ban_reason VARCHAR(500),
    target VARCHAR(255),
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT
) CHARACTER SET utf8;