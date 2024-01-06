-- Sensor under maintenance:
CREATE VIEW parking_schema.SENSORS_UNDER_MAINTENANCE AS
SELECT
PS.SENSOR_ID, PS.TAG, PAS.NAME, 'MAINTENANCE' AS STATUS
FROM parking_schema.PARKING_SENSOR PS
JOIN parking_schema.PARKING_SPACE PAS ON PAS.SPACE_ID = PS.SPACE_ID
WHERE STATUS = 'INACTIVE';

-- Sensor that are working:
CREATE VIEW parking_schema.WORING_SENSORS AS
SELECT
PS.SENSOR_ID, PS.TAG, PAS.NAME, 'WORKING' AS STATUS
FROM parking_schema.PARKING_SENSOR PS
JOIN parking_schema.PARKING_SPACE PAS ON PAS.SPACE_ID = PS.SPACE_ID
WHERE STATUS = 'ACTIVE';

-- Daily parking entry trends:
CREATE VIEW parking_schema.DAILY_PARKING_ENTRY_TRENDS AS
SELECT COUNT(*) AS TOTAL, DATE_TRUNC('day', GSR.DATE) AS DAY
FROM parking_schema.GATE_SENSOR_READING GSR
JOIN parking_schema.GATES GA ON GA.SENSOR_TAG = GSR.SENSOR_TAG
WHERE GA.NAME = 'ENTRY'
GROUP BY DAY, TOTAL;

-- Daily parking exit trends:
CREATE VIEW parking_schema.DAILY_PARKING_EXIT_TRENDS AS
SELECT COUNT(*) AS TOTAL, DATE_TRUNC('day', GSR.DATE) AS DAY
FROM parking_schema.GATE_SENSOR_READING GSR
JOIN parking_schema.GATES GA ON GA.SENSOR_TAG = GSR.SENSOR_TAG
WHERE GA.NAME = 'EXIT'
GROUP BY DAY, TOTAL;