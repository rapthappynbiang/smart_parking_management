-- USER WALLET HISTORY -- 
SELECT * FROM USER_WALLET_HISTORY WHERE WALLET_ID = 1;
CREATE INDEX USER_WALLET_HISTORY_INDEX ON USER_WALLET_HISTORY(WALLET_HISTORY_ID) WHERE WALLET_HISTORY_ID IS NOT NULL;
EXPLAIN SELECT * FROM USER_WALLET_HISTORY WHERE WALLET_HISTORY_ID = 1;
-- PARKING SPACES --
SELECT * FROM PARKING_SPACE WHERE SPACE_ID = 1;
CREATE INDEX PARKING_SPACE_INDEX ON PARKING_SPACE(SPACE_ID) WHERE SPACE_ID IS NOT NULL;
EXPLAIN SELECT * FROM PARKING_SPACE WHERE SPACE_ID = 1;
-- WALLET BALANCE --
SELECT * FROM USER_WALLET WHERE WALLET_ID = 1;
CREATE INDEX WALLET_BALANCE_INDEX ON USER_WALLET(WALLET_ID) WHERE WALLET_ID IS NOT NULL;
EXPLAIN SELECT * FROM USER_WALLET WHERE WALLET_ID = 1;