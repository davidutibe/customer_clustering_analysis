-- RFM Customer Categorization Model

-- Data Aggregation and Frequency calculation (F Value)
WITH BaseData AS (
    SELECT 
        Customer_Name,
        MAX(DATEADD(year, 12, Order_Date)) AS Last_Order_Date,
        COUNT(DISTINCT Order_id) AS F_Value,
        SUM(Sales) AS Total_Sales,
        SUM(Order_Quantity) AS Total_Quantity
    FROM dbo.[Orders]
    WHERE Customer_Name IS NOT NULL
    GROUP BY Customer_Name
),
-- Recency and Monetary Value Calculations (R & M Values)
RFM_Calculation AS (
    SELECT 
        Customer_Name,
        DATEDIFF(day, Last_Order_Date, GETDATE()) AS R_Value,
        F_Value,
        CAST(Total_Sales AS BIGINT) AS M_Value
    FROM BaseData
),
-- Ranking Customer Recency Value (R Score Calculation)
R_Score AS (
    SELECT 
        Customer_Name,
        R_Value,
        CASE 
			WHEN ntile(5) OVER(Order by R_Value asc) = 1 THEN '5'
			WHEN ntile(5) OVER(Order by R_Value asc) = 2 THEN '4'
			WHEN ntile(5) OVER(Order by R_Value asc) = 3 THEN '3'
			WHEN ntile(5) OVER(Order by R_Value asc) = 4 THEN '2'
			ELSE '1'
		END AS R_Score
    FROM RFM_Calculation
),
-- Ranking Customer Frequency Value (F Score Calculation)
F_Score AS (
    SELECT 
        Customer_Name,
        F_Value,
		CASE
			WHEN ntile(5) OVER(ORDER BY F_Value asc) = 1 THEN '1'
			WHEN ntile(5) OVER(ORDER BY F_Value asc) = 2 THEN '2'
			WHEN ntile(5) OVER(ORDER BY F_Value asc) = 3 THEN '3'
			WHEN ntile(5) OVER(ORDER BY F_Value asc) = 4 THEN '4'
			ELSE '5'
		END AS F_Score
    FROM RFM_Calculation
),
-- Ranking Customer Monetary Value (M Score Calculation)
M_Score AS (
    SELECT 
        Customer_Name,
        M_Value,
        CASE
			WHEN ntile(5) OVER(Order by M_Value asc) = 1 THEN '1'
			WHEN ntile(5) OVER(Order by M_Value asc) = 2 THEN '2'
			WHEN ntile(5) OVER(Order by M_Value asc) = 3 THEN '3'
			WHEN ntile(5) OVER(Order by M_Value asc) = 4 THEN '4'
			ELSE '5'
		END AS M_Score
    FROM RFM_Calculation
),
-- Combining R, F, & M scores
FinalRFM AS (
    SELECT 
        r.Customer_Name,
        r.R_Value,
        r.R_Score,
        f.F_Value,
        f.F_Score,
        m.M_Value,
        m.M_Score,
        CONCAT(r.R_Score, f.F_Score, m.M_Score) AS RFM_Score
    FROM R_Score r
    JOIN F_Score f ON r.Customer_Name = f.Customer_Name
    JOIN M_Score m ON r.Customer_Name = m.Customer_Name
)
-- Fetching Customer Segment from Categorization table

SELECT F.*, C.Segment as Segment
FROM FinalRFM F
	Join dbo.[RFM Customer Categorization] C
		on F.RFM_Score = C.Scores
ORDER BY RFM_Score DESC;