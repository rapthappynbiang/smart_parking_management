---------- TRIGGERS ----------
BEGIN
-- TRIGGER FOR CREATING WALLET FOR USER --
CREATE OR REPLACE FUNCTION CREATE_WALLET_ON_REG_USER()
RETURNS TRIGGER LANGUAGE 'PLPGSQL'
AS $$
BEGIN
    INSERT INTO USER_WALLET(USER_ID, BALANCE) VALUES (NEW.USER_ID, 0);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS;
CREATE TRIGGER CREATE_WALLET_ON_REG_USER_TRIGGER
AFTER INSERT
ON USERS
FOR EACH ROW EXECUTE FUNCTION CREATE_WALLET_ON_REG_USER();

-- TRIGGER FOR ENTRY SENSOR READING ON ENTRY(can implement at api level) --
CREATE OR REPLACE FUNCTION ASSIGN_PARKING_SPACE_TO_USER()
RETURNS TRIGGER LANGUAGE 'PLPGSQL' 
AS $$
DECLARE  
SID INTEGER
UID INTEGER
IS_ENTRY BOOLEAN
BEGIN
    SELECT TYPE ILIKE 'ENTRY'  INTO IS_ENTRY FROM PARKING_GATES WHERE SENSOR_TAG = NEW.SENSOR_TAG;
	IF EXISTS (SELECT MIN(SPACE_ID) INTO SID FROM PARKING_SPACE WHERE STATUS ILIKE 'AVAILABLE' AND SELECT USER_ID INTO UID 
			   FROM USERS WHERE RFID_TAG = CRPTY(NEW.RFID_TAG, RFID_TAG)) AND IS_ENTRY
	THEN 
	INSERT INTO USER_PARKING_HISTORY(USER_ID, SPACE_ID,ENTRY_TIME) VALUES (UID, SID,CURRENT_TIMESTAMP)
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS;
CREATE TRIGGER ASSIGN_PARKING_SPACE_TO_USER
AFTER INSERT ON GATE_SENSOR_READING
FOR EACH ROW EXECUTE FUNCTION ASSIGN_PARKING_SPACE_TO_USER()

-- TRIGGER FOR ENTRY SENSOR READING ON EXIT (can implement at api level) --
CREATE OR REPLACE FUNCTION CHECK_USER_PAYMENT_STATUS()
RETURNS TRIGGER LANGUAGE 'PLPGSQL' 
AS $$
DECLARE  
SID INTEGER
UID INTEGER
IS_EXIT BOOLEAN
BEGIN
    SELECT TYPE ILIKE 'EXIT'  INTO IS_EXIT FROM PARKING_GATES WHERE SENSOR_TAG = NEW.SENSOR_TAG;
    SELECT USER_ID INTO UID FROM USERS WHERE RFID_TAG = CRPTY(NEW.RFID_TAG, RFID_TAG);
	IF EXISTS (SELECT STATUS ILIKE 'PAID' FROM BILL WHERE USER_ID=UID) AND IS_EXIT
	THEN 
	UPDATE USER_PARKING_HISTORY SET EXIT_TIME = CURRENT_TIMESTAMP WHERE USER_ID = UID AND EXIT_TIME = NULL;
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS;
CREATE TRIGGER CHECK_USER_PAYMENT_STATUS
AFTER INSERT ON GATE_SENSOR_READING
FOR EACH ROW EXECUTE FUNCTION CHECK_USER_PAYMENT_STATUS()
			   
-- TRIGGER FOR CHECK-IN OF VEHICLES ---------
CREATE OR REPLACE FUNCTION CHECK_IN()
RETURNS TRIGGER LANGUAGE 'PLPGSQL'
AS $$
SID INTEGER
PID INTEGER
BEGIN
    
	IF EXISTS(SELECT PS.SPACE_ID INTO SID FROM
			  PARKING_SENSOR_READING PSR
			  JOIN PARKING_SENSOR PS ON PS.SENSOR_ID = PSR.SENSOR_ID
			  WHERE NEW.SENSOR_ID = PS.SENSOR_ID
			  AND
			  SELECT PARKING_ID INTO PID 
			  FROM USER_PARKING_HISTORY UPH
			  WHERE CHECK_IN =NULL AND CHECK_OUT = NULL AND SPACE_ID=SID) THEN
			    UPDATE USER_PARKING_HISTORY SET CHECK_IN = CURRENT_TIMESTAMP WHERE PARKING_ID=PID;
	END IF;
RETURN NEW;
END;
$$;

DROP TRIGGER CHECK_IN;
CREATE TRIGGER CHECK_IN
AFTER INSERT ON PARKING_SENSOR_READING
WHEN (NEW.READING =0 AND OLD.READING=1) -- INCOMING DATA AND OLD DATA NEEDS TOBE DIFFERENT 0 INDICATES CHECKIN 
FOR EACH ROW EXECUTE FUNCTION CHECK_IN();

-- TRIGGER FOR CHECK-OUT OF VEHICLES(can implement at api level) ---------
CREATE OR REPLACE FUNCTION CHECK_OUT()
RETURNS TRIGGER LANGUAGE 'PLPGSQL'
AS $$
SID INTEGER
PID INTEGER
BEGIN
    
	IF EXISTS(SELECT PS.SPACE_ID INTO SID FROM
			  PARKING_SENSOR_READING PSR
			  JOIN PARKING_SENSOR PS ON PS.SENSOR_ID = PSR.SENSOR_ID
			  WHERE NEW.SENSOR_ID = PS.SENSOR_ID
			  AND
			  SELECT PARKING_ID INTO PID 
			  FROM USER_PARKING_HISTORY UPH
			  WHERE CHECK_IN =NULL AND CHECK_OUT = NULL AND SPACE_ID=SID) THEN
			    UPDATE USER_PARKING_HISTORY SET CHECK_OUT = CURRENT_TIMESTAMP WHERE PARKING_ID=PID;
	END IF;
RETURN NEW;
END;
$$;

DROP TRIGGER CHECK_OUT;
CREATE TRIGGER CHECK_OUT
AFTER INSERT ON PARKING_SENSOR_READING
WHEN (NEW.READING =1 AND OLD.READING=0) -- INCOMING DATA AND OLD DATA NEEDS TOBE DIFFERENT 0 INDICATES CHECKIN 
FOR EACH ROW EXECUTE FUNCTION CHECK_OUT();

-- TRIGGER FOR GENERATE BILL OF USER ---------------------------------------
CREATE OR REPLACE FUNCTION GENERATE_BILL_FOR_USER()
RETURNS TRIGGER LANGUAGE 'PLPGSQL'
AS $$
DECLARE 
  AMOUNT NUMERIC;
  B NUMERIC;
BEGIN 
  SELECT (EXTRACT(EPOCH FROM (NEW.CHECK_IN - NEW.CHECK_OUT)) / 60 ) * ST.RATE_PER_MIN INTO AMOUNT 
  FROM PARKING_SPACE PS
  JOIN SPACE_TYPE ST ON ST.SPACE_TYPE = PS.SPACE_TYPE
  WHERE PS.SPACE_ID = NEW.SPACE_ID;

  SELECT INTO BALANCE B FROM USER_WALLET WHERE USER_ID = NEW.USER_ID;

  IF B < AMOUNT THEN
    INSERT INTO BILL (USER_ID, AMOUNT, DATE, STATUS) VALUES (NEW.USER_ID, AMOUNT, CURRENT_TIMESTAMP, 'PENDING');
  ELSE
    INSERT INTO BILL (PARKING_ID, USER_ID, AMOUNT, DATE, STATUS) VALUES (NEW.PARKING_ID, NEW.USER_ID, AMOUNT, CURRENT_TIMESTAMP, 'PAID');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS TRIGGER_GENERATE_BILL_FOR_USER ON USER_PARKING_HISTORY;

CREATE TRIGGER TRIGGER_GENERATE_BILL_FOR_USER
AFTER UPDATE ON USER_PARKING_HISTORY
FOR EACH ROW
WHEN (NEW.CHECK_OUT IS NOT NULL)
EXECUTE FUNCTION GENERATE_BILL_FOR_USER();


-- DEDUCT BALANCE FROM USER WALLET TRIGGER -------
CREATE OR REPLACE FUNCTION DEDUCT_FROM_WALLET()
RETURNS TRIGGERS LANGUAGE PLPGSQL 
AS $$
BEGIN
  UPDATE USER_WALLET SET BALANCE = BALANCE - NEW.AMOUNT
  WHERE USER_ID = NEW.USER_ID;
RETURN NEW;
END;
$$;

CREATE TRIGGER DEDUCT_FROM_WALLET
AFTER INSERT ON BILL
WHEN (NEW.STATUS ILIKE 'PAID')
FOR EVERY ROW EXECUTE FUNCTION DEDUCT_FROM_WALLET();





