
-- Create a view named user_wallet_view
CREATE OR REPLACE VIEW user_wallet_view AS
SELECT
    u.EMAIL,
    u.PHONE,
    u.FIRST_NAME,
    u.LAST_NAME,
    u.STATUS,
    w.WALLET_ID,
    w.BALANCE
FROM
    USERS u
JOIN
    USER_WALLET w ON u.USER_ID = w.USER_ID
ORDER BY 
    U.USER_ID;


CREATE VIEW parking_schema.TWO_WHEELER_AVAILABLE_SPACES AS
SELECT
    PARKING_SPACE.NAME,
    PARKING_SPACE.TYPE
FROM
    PARKING_SPACE
WHERE
 PARKING_SPACE.STATUS = 'AVAILABLE';


CREATE VIEW parking_schema.FOUR_WHEELER_AVAILABLE_SPACES AS
SELECT
    PARKING_SPACE.NAME,
    PARKING_SPACE.TYPE
FROM
    PARKING_SPACE
WHERE
    PARKING_SPACE.TYPE = 'FOUR-WHEELER'
    AND PARKING_SPACE.STATUS = 'AVAILABLE';

CREATE VIEW parking_schema.SPACE_UNDER_MAINTENACE AS
SELECT
    NAME,
    TYPE
FROM
    PARKING_SPACE
WHERE
    STATUS = 'MAINTENANCE';


-- A query to fetch_monthly_income
    SELECT COALESCE(SUM(AMOUNT), 0)
    FROM parking_schema.BILL
    WHERE DATE >= start_date AND DATE <= end_date AND STATUS ILIKE 'PAID';

