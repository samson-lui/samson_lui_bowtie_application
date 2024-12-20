/*Q5(1A)*/

CREATE TABLE CLAIM_2021 AS
SELECT A.*,
B.PRODUCT 
FROM CLAIM A
LEFT JOIN POLICY B
ON A.POLICY_NUMBER=B.POLICY_NUMBER
WHERE DATEPART('01-01-2021'D)<=A.SUBMIT_DATE <=DATEPART('31-12-2021'D);

CREATE TABLE SUMMARY AS
SELECT DISTINCT PRODUCT,COUNT(TYPE) AS CLAIM_CNT
FROM CLAIM_2021
GROUP BY PRODUCT;


/*Q5(1B)*/

CREATE TABLE POLICY_CNT AS
SELECT DISTINCT USER_ID,CNT(USER_ID) AS CNT 
FROM POLICY;

CREATE TABLE SINGLE_POLICY AS
SELECT * FROM POLICY_CNT
WHERE CNT = 1;

CREATE TABLE MULTI_POLICY AS
SELECT * FROM POLICY_CNT
WHERE CNT > 1;

CREATE FIRST_POLICY AS
SELECT USER_ID, POLICY_NUMBER, MIN(DATE) FROM POLICY
WHERE USER_ID IN (SELECT USER_ID FROM MULTI_POLICY)
GROUP BY USER_ID;

CREATE TABLE NEW_POLICY AS
SELECT * FROM POLICY
WHERE USER_ID IN (SELECT USER_ID FROM SINGLE_POLICY)
OR POLICY_NUMBER IN (SELECT POLICY_NUMBER FROM FIRST_POLICY);

CREATE TABLE RETURN_POLICY AS
SELECT * FROM POLICY
WHERE USER_ID NOT IN (SELECT USER_ID FROM SINGLE_POLICY)
AND POLICY_NUMBER NOT IN (SELECT POLICY_NUMBER FROM FIRST_POLICY);

CREATE TABLE NET_PREMIUM_RAW AS
SELECT A.POLICY_NUMBER,
A.TOTAL_AMOUNT,
B.TOTAL_BILLED_AMOUNT
FROM INVOICE AS A 
LEFT JOIN CLAIM AS B
ON A.POLICY_NUMBER = B.POLICY_NUMBER
WHERE A.STATUS NOT IN ("REFUNDED" "VOID") AND B.STATUS NOT IN ("CANCELED" "DECLINED" "WITHDRAWN");

CREATE TABLE NET_PREMIUM AS
SELECT DISCTINCT POLICY_NUMBER,
SUM(TOTAL_AMOUNT)-SUM(TOTAL_BILLED_AMOUNT) AS NET_PREMIUM
FROM NET_PREMIUM_RAW GROUP BY POLICY_NUMBER;

CREATE TABLE NET_PREMIUM AS
SELECT *,
CASE WHEN POLICY_NUMBER IN (SELECT POLICY_NUMBER IN NEW_POLICY) THEN "NEW_POLICY" ELSE WHEN POLICY_NUMBER IN (SELECT POLICY_NUMBER IN RETURN_POLICY) THEN "RETURN_POLICY" ELSE "N/A" END AS POLICY_CATEGORY
FROM NET_PREMIUM;

CREATE TABLE SUMMARY AS
SELECT DISTINCT POLICY_CATEGORY,
SUM(NET_PREMIUM) AS SUM_OF_NET_PREMIUM
FROM NET_PREMIUM GROUP BY POLICY_CATEGORY;

/*assume Net Premium = TOTAL_AMOUNT (from invoice) - TOTAL_BILLED_AMOUNT (from claim)*/